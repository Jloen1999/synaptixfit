package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.admin;

import com.synaptixfit.domain.model.admin.AcademicProfileSnapshot;
import com.synaptixfit.domain.model.admin.AdminActivityAggregation.StudyInterval;
import com.synaptixfit.domain.model.admin.AdminActivityAggregation.StudyWeek;
import com.synaptixfit.domain.model.admin.AdminActivityAggregation.UserFocus;
import com.synaptixfit.domain.model.admin.AdminUserCounts;
import com.synaptixfit.domain.model.admin.AdminUserSummary;
import com.synaptixfit.domain.model.admin.AuditAction;
import com.synaptixfit.domain.model.admin.TimelineEntry;
import com.synaptixfit.domain.model.admin.UserSearchCriteria;

import com.synaptixfit.domain.model.admin.WellbeingProfileSnapshot;
import com.synaptixfit.domain.model.analytics.WeeklyTrainingMetric.CompletedSession;
import com.synaptixfit.domain.model.planner.ActivityType;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import com.synaptixfit.domain.model.user.Role;
import com.synaptixfit.domain.port.output.admin.AdminUserQueryPort;
import com.synaptixfit.infrastructure.adapter.output.persistence.adapter.SqlLike;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.Instant;
import java.time.LocalDate;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Repository;

/**
 * Implementa {@link AdminUserQueryPort}: lecturas con JdbcClient sobre {@code usuarios} y las
 * tablas de actividad de los demás módulos (solo lectura). SQL estándar y sin reglas: la adherencia,
 * los minutos de estudio y las series semanales los calcula {@code AdminActivityAggregation} en
 * {@code AdminUserQueryService}.
 */
@Repository
public class AdminUserQueryJdbcAdapter implements AdminUserQueryPort {

    /** Bloques que cuentan como estudio: la definición única del planificador ({@link ActivityType#countsAsStudy()}). */
    private static final List<String> STUDY_TYPES = ActivityType.codesWhere(ActivityType::countsAsStudy);

    /** Recuentos y sumas simples; las reglas (adherencia, minutos de estudio) se calculan en el dominio. */
    private static final String STATS = """
            SELECT
              (SELECT count(*) FROM sesiones_registradas WHERE usuario_id = :id AND completada_en IS NOT NULL) AS training_sessions,
              (SELECT COALESCE(sum(duracion_minutos), 0) FROM sesiones_registradas WHERE usuario_id = :id AND completada_en IS NOT NULL) AS training_minutes,
              (SELECT COALESCE(round(sum(calorias_quemadas)), 0) FROM sesiones_registradas WHERE usuario_id = :id AND completada_en IS NOT NULL) AS calories,
              (SELECT round(avg(rpe), 1) FROM sesiones_registradas WHERE usuario_id = :id AND completada_en IS NOT NULL) AS average_rpe,
              (SELECT count(*) FROM rutinas WHERE usuario_id = :id AND eliminado_en IS NULL) AS routines,
              (SELECT count(*) FROM rutinas WHERE usuario_id = :id AND eliminado_en IS NULL AND estado = 'activo') AS active_routines,
              (SELECT count(*) FROM retos WHERE usuario_id = :id) AS challenges,
              (SELECT count(*) FROM retos WHERE usuario_id = :id AND esta_completado = true) AS completed_challenges,
              (SELECT count(*) FROM usuario_insignias WHERE usuario_id = :id) AS badges,
              (SELECT count(*) FROM asignaturas WHERE usuario_id = :id AND archivado = false) AS subjects,
              (SELECT count(*) FROM apuntes WHERE usuario_id = :id) AS notes,
              (SELECT count(*) FROM archivos_asignatura WHERE usuario_id = :id) AS files,
              (SELECT count(*) FROM horarios_academicos
                WHERE usuario_id = :id AND completado = true AND tipo_actividad IN (:studyTypes)) AS completed_blocks,
              (SELECT count(*) FROM sesiones_focus
                WHERE usuario_id = :id AND completada = true AND tipo_fase = 'focus') AS focus_sessions,
              (SELECT COALESCE(sum(duracion_minutos), 0) FROM sesiones_focus
                WHERE usuario_id = :id AND completada = true AND tipo_fase = 'focus') AS focus_minutes,
              (SELECT count(*) FROM entregas_examenes WHERE usuario_id = :id AND esta_completado = true) AS completed_deadlines,
              (SELECT count(*) FROM entregas_examenes WHERE usuario_id = :id AND esta_completado = false) AS pending_deadlines,
              (SELECT count(*) FROM actividades_sociales WHERE usuario_id = :id) AS posts,
              (SELECT count(*) FROM comentarios_feed WHERE usuario_id = :id AND eliminado = false) AS comments,
              (SELECT count(*) FROM amistades
                WHERE (solicitante_id = :id OR receptor_id = :id) AND estado = 'aceptada') AS friends,
              (SELECT max(x.t) FROM (
                  SELECT max(completada_en) AS t FROM sesiones_registradas WHERE usuario_id = :id
                  UNION ALL SELECT max(hora_fin) FROM horarios_academicos WHERE usuario_id = :id AND completado = true
                  UNION ALL SELECT max(creado_en) FROM sesiones_focus WHERE usuario_id = :id) x) AS last_activity
            """;

    /**
     * Actividad visible en la línea de tiempo. La duración de los bloques se calcula en Java con
     * {@code inicio} y {@code fin}, sin funciones de fecha propias de un motor. La primera rama da
     * tipo a sus columnas vacías con {@code NULLIF(x, x)} (un NULL con el tipo de x) en lugar de un
     * cast propio de PostgreSQL: así la unión resuelve los tipos igual en cualquier motor.
     */
    private static final String TIMELINE = """
            SELECT creado_en AS occurred_at, 'ACCOUNT_CREATED' AS tipo, id AS referencia,
                   NULLIF(nombre_completo, nombre_completo) AS titulo, NULLIF(nivel, nivel) AS valor,
                   NULLIF(creado_en, creado_en) AS inicio, NULLIF(creado_en, creado_en) AS fin
              FROM usuarios WHERE id = :id
            UNION ALL
            SELECT s.completada_en, 'TRAINING_SESSION', s.id, r.nombre, s.duracion_minutos, NULL, NULL
              FROM sesiones_registradas s LEFT JOIN rutinas r ON r.id = s.rutina_id
             WHERE s.usuario_id = :id AND s.completada_en IS NOT NULL
            UNION ALL
            SELECT creado_en, 'ROUTINE_CREATED', id, nombre, NULL, NULL, NULL FROM rutinas WHERE usuario_id = :id
            UNION ALL
            SELECT creado_en, 'CHALLENGE_CREATED', id, titulo, NULL, NULL, NULL FROM retos WHERE usuario_id = :id
            UNION ALL
            SELECT actualizado_en, 'CHALLENGE_COMPLETED', id, titulo, NULL, NULL, NULL
              FROM retos WHERE usuario_id = :id AND esta_completado = true
            UNION ALL
            SELECT ui.obtenida_en, 'BADGE_EARNED', ui.insignia_id, i.nombre, NULL, NULL, NULL
              FROM usuario_insignias ui JOIN insignias i ON i.id = ui.insignia_id
             WHERE ui.usuario_id = :id
            UNION ALL
            SELECT COALESCE(h.asistencia_registrada_en, h.hora_fin), 'STUDY_BLOCK_COMPLETED', h.id,
                   COALESCE(a.nombre, h.tipo_actividad), NULL, h.hora_inicio, h.hora_fin
              FROM horarios_academicos h LEFT JOIN asignaturas a ON a.id = h.asignatura_id
             WHERE h.usuario_id = :id AND h.completado = true
            UNION ALL
            SELECT actualizado_en, 'DEADLINE_COMPLETED', id, titulo, NULL, NULL, NULL
              FROM entregas_examenes WHERE usuario_id = :id AND esta_completado = true
            UNION ALL
            SELECT creado_en, 'NOTE_CREATED', id, titulo, NULL, NULL, NULL FROM apuntes WHERE usuario_id = :id
            UNION ALL
            SELECT creado_en, 'FOCUS_SESSION', id, NULL, duracion_minutos, NULL, NULL
              FROM sesiones_focus WHERE usuario_id = :id AND completada = true AND tipo_fase = 'focus'
            UNION ALL
            SELECT creado_en, 'POST_PUBLISHED', id, descripcion, NULL, NULL, NULL
              FROM actividades_sociales WHERE usuario_id = :id
            UNION ALL
            SELECT creado_en, 'COMMENT_POSTED', id, texto, NULL, NULL, NULL
              FROM comentarios_feed WHERE usuario_id = :id AND eliminado = false
            UNION ALL
            SELECT creado_en, 'ADMIN_ACTION', id, accion, NULL, NULL, NULL FROM admin_auditoria WHERE entidad_id = :id
            """;

    /** Longitud máxima del extracto de publicaciones y comentarios en la línea de tiempo. */
    private static final int EXCERPT_LENGTH = 120;

    private final JdbcClient jdbc;

    public AdminUserQueryJdbcAdapter(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    @Override
    public PageResult<AdminUserSummary> search(UserSearchCriteria criteria, PageRequest page) {
        StringBuilder where = new StringBuilder(" WHERE 1 = 1");
        Map<String, Object> params = new LinkedHashMap<>();
        if (criteria.text() != null) {
            where.append(" AND (lower(email) LIKE :text " + SqlLike.ESCAPE + " OR lower(nombre_completo) LIKE :text "
                    + SqlLike.ESCAPE + ")");
            params.put("text", SqlLike.contains(criteria.text().toLowerCase(Locale.ROOT)));
        }
        if (criteria.role() != null) {
            where.append(" AND rol = :role");
            params.put("role", criteria.role() == Role.ADMIN ? "admin" : "usuario");
        }
        if (criteria.shadowbanned() != null) {
            where.append(" AND is_shadowbanned = :shadowbanned");
            params.put("shadowbanned", criteria.shadowbanned());
        }
        switch (criteria.status()) {
            case ACTIVE -> where.append(" AND eliminado_en IS NULL");
            case DELETED -> where.append(" AND eliminado_en IS NOT NULL");
            case ALL -> { }
        }
        if (criteria.minLevel() != null) {
            where.append(" AND nivel >= :minLevel");
            params.put("minLevel", criteria.minLevel());
        }
        if (criteria.maxLevel() != null) {
            where.append(" AND nivel <= :maxLevel");
            params.put("maxLevel", criteria.maxLevel());
        }
        long total = jdbc.sql("SELECT count(*) FROM usuarios" + where).params(params).query(Long.class).single();
        Map<String, Object> pageParams = new LinkedHashMap<>(params);
        pageParams.put("limit", page.size());
        pageParams.put("offset", page.offset());
        List<AdminUserSummary> items = jdbc.sql("""
                        SELECT id, email, nombre_completo, url_avatar, rol, nivel, xp_nivel_actual, racha_actual,
                               is_shadowbanned, creado_en, eliminado_en
                          FROM usuarios""" + where + orderBy(criteria) + " LIMIT :limit OFFSET :offset")
                .params(pageParams)
                .query((rs, n) -> new AdminUserSummary(
                        JdbcValues.uuid(rs, "id"),
                        rs.getString("email"),
                        rs.getString("nombre_completo"),
                        rs.getString("url_avatar"),
                        "admin".equals(rs.getString("rol")) ? Role.ADMIN : Role.USER,
                        rs.getInt("nivel"),
                        rs.getInt("xp_nivel_actual"),
                        rs.getInt("racha_actual"),
                        rs.getBoolean("is_shadowbanned"),
                        JdbcValues.instant(rs, "creado_en"),
                        JdbcValues.instant(rs, "eliminado_en")))
                .list();
        return new PageResult<>(items, page.page(), page.size(), total);
    }

    @Override
    public Optional<WellbeingProfileSnapshot> findWellbeingProfile(UUID userId) {
        return jdbc.sql("""
                        SELECT edad, sexo, peso_kg, altura_cm, imc, nivel_actividad, objetivo_principal,
                               dias_disponibles_semana, minutos_por_sesion, onboarding_completado
                          FROM perfil_bienestar_usuario WHERE usuario_id = :id
                         ORDER BY actualizado_en DESC LIMIT 1
                        """)
                .param("id", userId)
                .query((rs, n) -> new WellbeingProfileSnapshot(
                        rs.getInt("edad"),
                        rs.getString("sexo"),
                        rs.getObject("peso_kg", Double.class),
                        rs.getObject("altura_cm", Double.class),
                        rs.getObject("imc", Double.class),
                        rs.getString("nivel_actividad"),
                        rs.getString("objetivo_principal"),
                        rs.getInt("dias_disponibles_semana"),
                        rs.getInt("minutos_por_sesion"),
                        rs.getBoolean("onboarding_completado")))
                .optional();
    }

    @Override
    public Optional<AcademicProfileSnapshot> findAcademicProfile(UUID userId) {
        return jdbc.sql("""
                        SELECT universidad, carrera, semestre_actual, modalidad, creditos_semestre_actual,
                               horas_objetivo_estudio_semana, promedio_objetivo, fecha_inicio_clases, fecha_fin_clases
                          FROM perfil_academico_usuario WHERE usuario_id = :id
                         ORDER BY actualizado_en DESC LIMIT 1
                        """)
                .param("id", userId)
                .query((rs, n) -> new AcademicProfileSnapshot(
                        rs.getString("universidad"),
                        rs.getString("carrera"),
                        rs.getInt("semestre_actual"),
                        rs.getString("modalidad"),
                        rs.getInt("creditos_semestre_actual"),
                        rs.getInt("horas_objetivo_estudio_semana"),
                        rs.getObject("promedio_objetivo", Double.class),
                        JdbcValues.date(rs, "fecha_inicio_clases"),
                        JdbcValues.date(rs, "fecha_fin_clases")))
                .optional();
    }

    @Override
    public List<StudyWeek> recentStudyWeeks(UUID userId, int weeks) {
        return jdbc.sql("""
                        SELECT horas_estudio_planeadas, horas_estudio_reales FROM carga_academica_semanal
                         WHERE usuario_id = :id ORDER BY semana_inicio DESC LIMIT :weeks
                        """)
                .param("id", userId).param("weeks", weeks)
                .query((rs, n) -> new StudyWeek(rs.getInt("horas_estudio_planeadas"), rs.getInt("horas_estudio_reales")))
                .list();
    }

    @Override
    public AdminUserCounts counts(UUID userId) {
        return jdbc.sql(STATS)
                .param("id", userId)
                .param("studyTypes", STUDY_TYPES)
                .query((rs, n) -> new AdminUserCounts(
                        rs.getLong("training_sessions"),
                        rs.getLong("training_minutes"),
                        rs.getLong("calories"),
                        JdbcValues.nullableDouble(rs, "average_rpe"),
                        rs.getLong("routines"),
                        rs.getLong("active_routines"),
                        rs.getLong("challenges"),
                        rs.getLong("completed_challenges"),
                        rs.getLong("badges"),
                        rs.getLong("subjects"),
                        rs.getLong("notes"),
                        rs.getLong("files"),
                        rs.getLong("completed_blocks"),
                        rs.getLong("focus_sessions"),
                        rs.getLong("focus_minutes"),
                        rs.getLong("completed_deadlines"),
                        rs.getLong("pending_deadlines"),
                        rs.getLong("posts"),
                        rs.getLong("comments"),
                        rs.getLong("friends"),
                        JdbcValues.instant(rs, "last_activity")))
                .single();
    }

    @Override
    public List<CompletedSession> completedTrainingSessions(UUID userId, Instant from, Instant to) {
        return jdbc.sql("""
                        SELECT completada_en, duracion_minutos, calorias_quemadas, rpe FROM sesiones_registradas
                         WHERE usuario_id = :id AND completada_en >= :fromTs AND completada_en < :toTs
                        """)
                .param("id", userId).param("fromTs", JdbcValues.param(from)).param("toTs", JdbcValues.param(to))
                .query((rs, n) -> new CompletedSession(JdbcValues.instant(rs, "completada_en"),
                        rs.getInt("duracion_minutos"), JdbcValues.nullableDouble(rs, "calorias_quemadas"),
                        JdbcValues.nullableInt(rs, "rpe")))
                .list();
    }

    @Override
    public List<UserFocus> completedFocus(UUID userId, LocalDate from, LocalDate to) {
        return jdbc.sql("""
                        SELECT usuario_id, fecha, duracion_minutos FROM sesiones_focus
                         WHERE usuario_id = :id AND completada = true AND tipo_fase = 'focus'
                           AND fecha >= :fromDay AND fecha < :toDay
                        """)
                .param("id", userId).param("fromDay", from).param("toDay", to)
                .query((rs, n) -> new UserFocus(JdbcValues.uuid(rs, "usuario_id"), JdbcValues.date(rs, "fecha"),
                        rs.getInt("duracion_minutos")))
                .list();
    }

    @Override
    public List<StudyInterval> completedStudyIntervals(UUID userId, Instant from, Instant to) {
        String range = from == null ? "" : " AND hora_inicio >= :fromTs AND hora_inicio < :toTs";
        JdbcClient.StatementSpec spec = jdbc.sql("SELECT hora_inicio, hora_fin FROM horarios_academicos"
                        + " WHERE usuario_id = :id AND completado = true AND tipo_actividad IN (:studyTypes)" + range)
                .param("id", userId).param("studyTypes", STUDY_TYPES);
        if (from != null) {
            spec = spec.param("fromTs", JdbcValues.param(from)).param("toTs", JdbcValues.param(to));
        }
        return spec.query((rs, n) -> new StudyInterval(JdbcValues.instant(rs, "hora_inicio"),
                JdbcValues.instant(rs, "hora_fin"))).list();
    }

    @Override
    public PageResult<TimelineEntry> timeline(UUID userId, PageRequest page) {
        long total = jdbc.sql("SELECT count(*) FROM (" + TIMELINE + ") t")
                .param("id", userId).query(Long.class).single();
        List<TimelineEntry> items = jdbc.sql("SELECT * FROM (" + TIMELINE + ") t"
                        + " ORDER BY t.occurred_at DESC, t.referencia LIMIT :limit OFFSET :offset")
                .param("id", userId)
                .param("limit", page.size())
                .param("offset", page.offset())
                .query((rs, n) -> toTimelineEntry(rs))
                .list();
        return new PageResult<>(items, page.page(), page.size(), total);
    }

    @Override
    public long countActiveAdmins() {
        return jdbc.sql("SELECT count(*) FROM usuarios WHERE rol = 'admin' AND eliminado_en IS NULL")
                .query(Long.class).single();
    }

    private static TimelineEntry toTimelineEntry(ResultSet rs) throws SQLException {
        TimelineEntry.Type type = TimelineEntry.Type.valueOf(rs.getString("tipo"));
        String title = rs.getString("titulo");
        if (type == TimelineEntry.Type.ADMIN_ACTION && title != null) {
            title = AuditAction.fromCode(title).name();
        } else if (title != null && title.length() > EXCERPT_LENGTH) {
            title = title.substring(0, EXCERPT_LENGTH);
        }
        Integer value = JdbcValues.nullableInt(rs, "valor");
        Instant start = JdbcValues.instant(rs, "inicio");
        Instant end = JdbcValues.instant(rs, "fin");
        if (value == null && start != null && end != null) {
            value = (int) Math.round(new StudyInterval(start, end).minutes());
        }
        return new TimelineEntry(JdbcValues.instant(rs, "occurred_at"), type, JdbcValues.uuid(rs, "referencia"),
                title, value);
    }

    private static String orderBy(UserSearchCriteria criteria) {
        String dir = criteria.direction() == UserSearchCriteria.SortDirection.ASC ? "ASC" : "DESC";
        String expression = switch (criteria.sort()) {
            case CREATED_AT -> "creado_en " + dir;
            // La experiencia total crece con (nivel, XP dentro del nivel) en orden lexicográfico, porque
            // la XP del nivel nunca alcanza el umbral del siguiente: ordenar así equivale a ordenar por
            // XP total sin repetir en SQL la fórmula de niveles (que vive en User).
            case LEVEL, XP -> "nivel " + dir + ", xp_nivel_actual " + dir;
            case NAME -> "lower(nombre_completo) " + dir;
            case STREAK -> "racha_actual " + dir;
        };
        return " ORDER BY " + expression + ", id";
    }
}
