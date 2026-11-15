package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.challenge;

import java.util.ArrayList;
import java.util.List;
import java.util.Set;
import com.synaptixfit.domain.model.academic.TestSessionStatus;
import com.synaptixfit.domain.model.challenge.ActivityFact;
import com.synaptixfit.domain.model.challenge.ActivityKind;
import com.synaptixfit.domain.model.planner.ActivitySource;
import com.synaptixfit.infrastructure.adapter.output.persistence.mapper.academic.AcademicDbCodes;
import com.synaptixfit.infrastructure.adapter.output.persistence.mapper.training.TrainingDbValues;
import com.synaptixfit.domain.model.training.RoutineStatus;
import com.synaptixfit.domain.model.training.ProgressStatus;
import com.synaptixfit.domain.model.challenge.RoutineDayTarget;
import com.synaptixfit.domain.model.challenge.StudyBlockProgress;
import com.synaptixfit.domain.model.training.TrainingRewards;
import com.synaptixfit.domain.port.output.challenge.ChallengeReferencePort;
import com.synaptixfit.infrastructure.adapter.output.persistence.adapter.CompletedWorkoutsSql;
import java.time.Instant;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.UUID;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Repository;

/**
 * Lecturas de propiedad sobre tablas de Académico ({@code asignaturas}, {@code apuntes},
 * {@code archivos_asignatura}) y Planificador ({@code entregas_examenes}, {@code horarios_academicos}),
 * y de Entrenamiento: recuento de sesiones completadas ({@code sesiones_registradas}) y días de la rutina en
 * curso ({@code dias_rutina}) para vincular tareas. Para los retos que se cuentan solos (ADR 0043) trae lo hecho en un
 * periodo: repasos, tests, Pomodoros, semanas planificadas, entrenos, carreras y días con registro diario (solo la
 * fecha: nunca las respuestas, que son datos de salud).
 */
@Repository
public class ChallengeReferencePersistenceAdapter implements ChallengeReferencePort {

    private final JdbcClient jdbc;

    public ChallengeReferencePersistenceAdapter(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    @Override
    public boolean subjectBelongsTo(UUID userId, UUID subjectId) {
        return owned("asignaturas", userId, subjectId);
    }

    @Override
    public boolean deadlineBelongsTo(UUID userId, UUID deadlineId) {
        return owned("entregas_examenes", userId, deadlineId);
    }

    @Override
    public boolean routineDayBelongsTo(UUID userId, UUID routineDayId) {
        return jdbc.sql("""
                        select count(*) from dias_rutina d
                        join semanas_rutina s on s.id = d.semana_id
                        join rutinas r on r.id = s.rutina_id
                        where d.id = :id and r.usuario_id = :user and r.eliminado_en is null
                        """)
                .param("id", routineDayId)
                .param("user", userId)
                .query(Long.class).single() > 0;
    }

    @Override
    public List<RoutineDayTarget> routineDayTargets(UUID userId) {
        String completed = TrainingDbValues.dayStatusToDb(ProgressStatus.COMPLETED);
        String skipped = TrainingDbValues.dayStatusToDb(ProgressStatus.SKIPPED);
        return jdbc.sql("""
                        select d.id, r.nombre as rutina, s.numero_semana, d.numero_dia, d.nombre as dia, d.estado,
                               (select count(*) from seleccion_de_ejercicios e where e.dia_id = d.id) as ejercicios
                        from dias_rutina d
                        join semanas_rutina s on s.id = d.semana_id
                        join rutinas r on r.id = s.rutina_id
                        where r.usuario_id = :user and r.estado = :active and r.eliminado_en is null
                        order by s.numero_semana, d.numero_dia
                        """)
                .param("user", userId)
                .param("active", TrainingDbValues.toDb(RoutineStatus.ACTIVE))
                .query((rs, n) -> {
                    String status = rs.getString("estado");
                    return new RoutineDayTarget(rs.getObject("id", UUID.class), rs.getString("rutina"),
                            rs.getInt("numero_semana"), rs.getInt("numero_dia"), rs.getString("dia"),
                            completed.equals(status) || skipped.equals(status), rs.getLong("ejercicios") > 0);
                })
                .list();
    }

    @Override
    public boolean noteBelongsTo(UUID userId, UUID noteId) {
        return owned("apuntes", userId, noteId);
    }

    @Override
    public boolean fileBelongsTo(UUID userId, UUID fileId) {
        return owned("archivos_asignatura", userId, fileId);
    }

    @Override
    public StudyBlockProgress studyBlockProgress(UUID userId, UUID milestoneId) {
        return jdbc.sql("""
                        select count(*) as total, coalesce(sum(case when completado then 1 else 0 end), 0) as done
                        from horarios_academicos where hito_id = :milestone and usuario_id = :user
                        """)
                .param("milestone", milestoneId)
                .param("user", userId)
                .query((rs, n) -> new StudyBlockProgress(rs.getInt("total"), rs.getInt("done")))
                .single();
    }

    @Override
    public int completedTrainingSessions(UUID userId, Instant from, Instant to) {
        // Entrenos hechos con la definición única (CompletedWorkoutsSql), la misma que Inicio y Progreso, con el mínimo
        // de minutos de TrainingRewards (ADR 0009) como parámetro.
        return jdbc.sql("""
                        select count(*) from %s e
                        where e.usuario_id = :user and e.terminado_en >= :from and e.terminado_en <= :to
                          and %s
                        """.formatted(CompletedWorkoutsSql.TABLE, CompletedWorkoutsSql.counted("e")))
                .param("user", userId)
                .param("minMinutes", TrainingRewards.MIN_COUNTED_MINUTES)
                .param("from", OffsetDateTime.ofInstant(from, ZoneOffset.UTC))
                .param("to", OffsetDateTime.ofInstant(to, ZoneOffset.UTC))
                .query(Long.class).single().intValue();
    }

    @Override
    public List<ActivityFact> activity(UUID userId, Set<ActivityKind> kinds, Instant from, Instant to) {
        OffsetDateTime start = OffsetDateTime.ofInstant(from, ZoneOffset.UTC);
        OffsetDateTime end = OffsetDateTime.ofInstant(to, ZoneOffset.UTC);
        List<ActivityFact> facts = new ArrayList<>();
        for (ActivityKind kind : kinds) {
            facts.addAll(switch (kind) {
                case REVIEW -> instants(kind, """
                        select r.fecha_repaso as hecho_en, 1 as cantidad from registros_repaso_srs r
                        join materiales_estudio m on m.id = r.material_estudio_id
                        where m.usuario_id = :user and r.fecha_repaso >= :from and r.fecha_repaso <= :to
                        """, userId, start, end);
                case TEST -> jdbc.sql("""
                                select completado_en as hecho_en, 1 as cantidad from test_sessions
                                where usuario_id = :user and status = :status
                                  and completado_en >= :from and completado_en <= :to
                                """)
                        .param("user", userId).param("from", start).param("to", end)
                        .param("status", AcademicDbCodes.sessionStatus(TestSessionStatus.COMPLETED))
                        .query((rs, n) -> ActivityFact.at(kind,
                                rs.getObject("hecho_en", OffsetDateTime.class).toInstant(), 1))
                        .list();
                // Se guarda al terminar la fase: creado_en es el final y la duración dice cuándo empezó.
                case FOCUS -> jdbc.sql("""
                                select creado_en as hecho_en, duracion_minutos as cantidad from sesiones_focus
                                where usuario_id = :user and completada = true and tipo_fase = :phase
                                  and creado_en >= :from and creado_en <= :to
                                """)
                        .param("user", userId).param("from", start).param("to", end)
                        .param("phase", FOCUS_PHASE)
                        .query((rs, n) -> ActivityFact.at(kind,
                                rs.getObject("hecho_en", OffsetDateTime.class).toInstant(), rs.getInt("cantidad")))
                        .list();
                case WORKOUT -> jdbc.sql("""
                                select e.terminado_en as hecho_en from %s e
                                where e.usuario_id = :user and e.terminado_en >= :from and e.terminado_en <= :to
                                  and %s
                                """.formatted(CompletedWorkoutsSql.TABLE, CompletedWorkoutsSql.counted("e")))
                        .param("user", userId).param("from", start).param("to", end)
                        .param("minMinutes", TrainingRewards.MIN_COUNTED_MINUTES)
                        .query((rs, n) -> ActivityFact.at(kind,
                                rs.getObject("hecho_en", OffsetDateTime.class).toInstant(), 1))
                        .list();
                // Desde la actividad apuntada con origen GPS (no desde carreras_gps): se guarda antes de marcar el
                // evento como hecho, así la carrera ya cuenta cuando llega SportBlockCompletionChanged.
                case RUN -> jdbc.sql("""
                                select b.hora_inicio as hecho_en from actividades_apuntadas a
                                join horarios_academicos b on b.id = a.bloque_id
                                where a.usuario_id = :user and a.clase = :run and a.origen = :gps
                                  and b.completado = true and b.hora_inicio >= :from and b.hora_inicio <= :to
                                """)
                        .param("user", userId).param("from", start).param("to", end)
                        .param("run", RUN_CLASS)
                        .param("gps", ActivitySource.GPS.name())
                        .query((rs, n) -> ActivityFact.at(kind,
                                rs.getObject("hecho_en", OffsetDateTime.class).toInstant(), 1))
                        .list();
                // La semana cuenta desde que se planificó (creado_en) y se agrupa por su lunes.
                case PLANNED_WEEK -> jdbc.sql("""
                                select creado_en, semana_inicio from planes_estudio
                                where usuario_id = :user and xp_planificacion_otorgado = true
                                  and creado_en >= :from and creado_en <= :to
                                """)
                        .param("user", userId).param("from", start).param("to", end)
                        .query((rs, n) -> new ActivityFact(kind,
                                rs.getObject("creado_en", OffsetDateTime.class).toInstant(),
                                rs.getObject("semana_inicio", LocalDate.class), 1))
                        .list();
                case CHECK_IN -> jdbc.sql("""
                                select fecha from estado_diario_usuario
                                where usuario_id = :user and fecha >= :fromDay and fecha <= :toDay
                                """)
                        .param("user", userId)
                        .param("fromDay", start.toLocalDate()).param("toDay", end.toLocalDate())
                        .query((rs, n) -> new ActivityFact(kind, null, rs.getObject("fecha", LocalDate.class), 1))
                        .list();
            });
        }
        return facts;
    }

    /** Clase «correr» de {@code actividades_apuntadas} (el enum del planificador se llama igual que el de retos). */
    private static final String RUN_CLASS = com.synaptixfit.domain.model.planner.ActivityKind.RUN.name();

    /** Fase de concentración del Pomodoro en {@code sesiones_focus.tipo_fase}. */
    private static final String FOCUS_PHASE = "focus";

    /** Filas con {@code hecho_en} (instante) y {@code cantidad} entre {@code :from} y {@code :to}. */
    private List<ActivityFact> instants(ActivityKind kind, String sql, UUID userId, OffsetDateTime from,
                                        OffsetDateTime to) {
        return jdbc.sql(sql)
                .param("user", userId).param("from", from).param("to", to)
                .query((rs, n) -> ActivityFact.at(kind, rs.getObject("hecho_en", OffsetDateTime.class).toInstant(),
                        rs.getInt("cantidad")))
                .list();
    }

    /** {@code table} es siempre una constante de esta clase, nunca un dato de entrada. */
    private boolean owned(String table, UUID userId, UUID id) {
        return jdbc.sql("select count(*) from " + table + " where id = :id and usuario_id = :user")
                .param("id", id)
                .param("user", userId)
                .query(Long.class).single() > 0;
    }
}
