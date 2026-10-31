package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.badge;

import com.synaptixfit.domain.model.academic.TestSessionStatus;
import com.synaptixfit.domain.model.badge.BadgeActivitySnapshot;
import com.synaptixfit.domain.model.badge.WeeklyStudyLoad;
import com.synaptixfit.domain.model.planner.ActivityType;
import com.synaptixfit.domain.model.planner.FocusRewards;
import com.synaptixfit.domain.model.planner.FocusSession;
import com.synaptixfit.domain.model.training.TrainingRewards;
import com.synaptixfit.domain.port.output.badge.UserActivityPort;
import com.synaptixfit.infrastructure.adapter.output.persistence.mapper.academic.AcademicDbCodes;
import com.synaptixfit.infrastructure.adapter.output.persistence.mapper.planner.PlannerPersistenceMapper;
import com.synaptixfit.infrastructure.adapter.output.persistence.mapper.social.SocialPersistenceMapper;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.time.ZoneId;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Repository;

/**
 * Lee la actividad del usuario en tablas de otros módulos: Entrenamiento
 * ({@code sesiones_registradas}), Bienestar ({@code estado_diario_usuario}), Planificador
 * ({@code horarios_academicos}, {@code planes_estudio}, {@code carga_academica_semanal}, {@code sesiones_focus}),
 * Académico ({@code apuntes}) y Social ({@code actividades_sociales}, {@code interacciones_sociales}).
 */
@Repository
public class UserActivityPersistenceAdapter implements UserActivityPort {

    private final JdbcClient jdbc;

    public UserActivityPersistenceAdapter(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    /**
     * Días activos de la racha: entrenamiento (sesiones y bloques de deporte), registro diario, Pomodoro y
     * también estudio (bloques de estudio o repaso completados, repasos SM-2 y tests terminados). Antes el estudio no contaba y quien
     * estudiaba con bloques veía racha 0 en la cabecera mientras el aviso de Inicio le daba racha de estudio.
     */
    @Override
    public Set<LocalDate> activeDays(UUID userId, ZoneId zone) {
        Set<LocalDate> days = new HashSet<>(sessionDays(userId, zone));
        days.addAll(checkInDays(userId));
        days.addAll(focusDays(userId));
        days.addAll(studyDays(userId, zone));
        return days;
    }

    @Override
    public BadgeActivitySnapshot snapshot(UUID userId, ZoneId zone) {
        // El umbral de RPE y los tipos de publicación excluidos son reglas del dominio: llegan como parámetros.
        int[] sessions = jdbc.sql("""
                        select count(*) as total,
                               coalesce(sum(case when rpe >= :highRpe then 1 else 0 end), 0) as high_rpe
                        from sesiones_registradas where usuario_id = :user and completada_en is not null
                          and duracion_minutos >= :minMinutes
                        """)
                .param("user", userId)
                .param("minMinutes", TrainingRewards.MIN_COUNTED_MINUTES)
                .param("highRpe", BadgeActivitySnapshot.HIGH_RPE_MIN)
                .query((rs, n) -> new int[]{rs.getInt("total"), rs.getInt("high_rpe")})
                .single();
        List<WeeklyStudyLoad> weeks = jdbc.sql("""
                        select semana_inicio, horas_estudio_planeadas, horas_estudio_reales
                        from carga_academica_semanal
                        where usuario_id = :user
                        order by semana_inicio desc
                        """)
                .param("user", userId)
                .query((rs, n) -> new WeeklyStudyLoad(rs.getObject("semana_inicio", LocalDate.class),
                        rs.getInt("horas_estudio_planeadas"), rs.getInt("horas_estudio_reales")))
                .list();
        return new BadgeActivitySnapshot(
                sessions[0],
                sessions[1],
                sessionDays(userId, zone),
                checkInDays(userId),
                countStudyBlocks(userId),
                count("select count(*) from planes_estudio where usuario_id = :user", userId),
                count("select count(*) from apuntes where usuario_id = :user", userId),
                jdbc.sql("select count(*) from actividades_sociales where usuario_id = :user and tipo not in (:automatic)")
                        .param("user", userId)
                        .param("automatic", BadgeActivitySnapshot.AUTOMATIC_POSTS.stream()
                                .map(SocialPersistenceMapper::postTypeToDb).toList())
                        .query(Long.class).single().intValue(),
                count("""
                        select count(*) from interacciones_sociales i
                        join actividades_sociales a on a.id = i.actividad_id
                        where a.usuario_id = :user and i.tipo_interaccion = 'like'
                        """, userId),
                count("select count(*) from retos where usuario_id = :user and esta_completado = true", userId),
                weeks);
    }

    private Set<LocalDate> sessionDays(UUID userId, ZoneId zone) {
        // Las sesiones demasiado cortas no cuentan (TrainingRewards.countsAsWorkout).
        return jdbc.sql("select completada_en from sesiones_registradas where usuario_id = :user"
                        + " and completada_en is not null and duracion_minutos >= :minMinutes")
                .param("user", userId)
                .param("minMinutes", TrainingRewards.MIN_COUNTED_MINUTES)
                .query((rs, n) -> rs.getObject("completada_en", OffsetDateTime.class))
                .list().stream()
                .map(t -> t.atZoneSameInstant(zone).toLocalDate())
                .collect(Collectors.toSet());
    }

    private Set<LocalDate> checkInDays(UUID userId) {
        return new HashSet<>(jdbc.sql("select distinct fecha from estado_diario_usuario where usuario_id = :user")
                .param("user", userId)
                .query((rs, n) -> rs.getObject("fecha", LocalDate.class))
                .list());
    }

    /** Bloques de estudio completados: estudio y repaso ({@link ActivityType#countsAsStudy()}). */
    private int countStudyBlocks(UUID userId) {
        return jdbc.sql("select count(*) from horarios_academicos where usuario_id = :user"
                        + " and tipo_actividad in (:types) and completado = true")
                .param("user", userId)
                .param("types", ActivityType.codesWhere(ActivityType::countsAsStudy))
                .query(Long.class).single().intValue();
    }

    /**
     * Días con una fase de concentración Pomodoro que cuenta para la racha ({@link FocusSession#countsForStreak()}:
     * terminada y de una duración mínima). {@code fecha} ya es el día local del planificador.
     */
    private Set<LocalDate> focusDays(UUID userId) {
        return new HashSet<>(jdbc.sql("select distinct fecha from sesiones_focus where usuario_id = :user"
                        + " and tipo_fase = :focus and completada = true and duracion_minutos >= :minMinutes")
                .param("user", userId)
                .param("focus", PlannerPersistenceMapper.phaseToDb(FocusSession.FocusPhase.FOCUS))
                .param("minMinutes", FocusRewards.MIN_CYCLE_MINUTES)
                .query((rs, n) -> rs.getObject("fecha", LocalDate.class))
                .list());
    }

    /** Días con bloques de estudio, repaso o deporte completados, repasos SM-2 o tests terminados. */
    private Set<LocalDate> studyDays(UUID userId, ZoneId zone) {
        Set<LocalDate> days = new HashSet<>();
        jdbc.sql("select hora_inicio as t from horarios_academicos where usuario_id = :user"
                        + " and tipo_actividad in (:types) and completado = true")
                .param("user", userId)
                .param("types", ActivityType.codesWhere(ActivityType::countsAsStudy))
                .query((rs, n) -> rs.getObject("t", OffsetDateTime.class)).list()
                .forEach(t -> days.add(t.atZoneSameInstant(zone).toLocalDate()));
        // Deporte sin rutina (CalendarBlock.countsAsPhysicalActivity): los de rutina ya cuentan por su sesión,
        // que filtra las demasiado cortas.
        jdbc.sql("select hora_inicio as t from horarios_academicos where usuario_id = :user"
                        + " and tipo_actividad = :sport and dia_rutina_id is null and completado = true")
                .param("user", userId)
                .param("sport", ActivityType.SPORT.code())
                .query((rs, n) -> rs.getObject("t", OffsetDateTime.class)).list()
                .forEach(t -> days.add(t.atZoneSameInstant(zone).toLocalDate()));
        jdbc.sql("select r.fecha_repaso as t from registros_repaso_srs r"
                        + " join materiales_estudio m on m.id = r.material_estudio_id where m.usuario_id = :user")
                .param("user", userId)
                .query((rs, n) -> rs.getObject("t", OffsetDateTime.class)).list()
                .forEach(t -> days.add(t.atZoneSameInstant(zone).toLocalDate()));
        jdbc.sql("select completado_en as t from test_sessions where usuario_id = :user"
                        + " and status = :completed and completado_en is not null")
                .param("user", userId)
                .param("completed", AcademicDbCodes.sessionStatus(TestSessionStatus.COMPLETED))
                .query((rs, n) -> rs.getObject("t", OffsetDateTime.class)).list()
                .forEach(t -> days.add(t.atZoneSameInstant(zone).toLocalDate()));
        return days;
    }

    private int count(String sql, UUID userId) {
        return jdbc.sql(sql).param("user", userId).query(Long.class).single().intValue();
    }
}
