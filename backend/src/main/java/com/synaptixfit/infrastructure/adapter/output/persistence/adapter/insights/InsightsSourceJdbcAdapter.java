package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.insights;

import static com.synaptixfit.infrastructure.adapter.output.persistence.adapter.insights.JdbcRows.date;
import static com.synaptixfit.infrastructure.adapter.output.persistence.adapter.insights.JdbcRows.decimal;
import static com.synaptixfit.infrastructure.adapter.output.persistence.adapter.insights.JdbcRows.instant;
import static com.synaptixfit.infrastructure.adapter.output.persistence.adapter.insights.JdbcRows.integer;
import static com.synaptixfit.infrastructure.adapter.output.persistence.adapter.insights.JdbcRows.param;
import static com.synaptixfit.infrastructure.adapter.output.persistence.adapter.insights.JdbcRows.uuid;

import com.synaptixfit.domain.model.insights.BodyProfile;
import com.synaptixfit.domain.model.insights.CompletedStudyBlock;
import com.synaptixfit.domain.model.insights.DailyCheckIn;
import com.synaptixfit.domain.model.insights.PracticeSessions;
import com.synaptixfit.domain.model.insights.WeeklyAcademicLoad;
import com.synaptixfit.domain.model.neuro.BiologicalSex;
import com.synaptixfit.domain.model.planner.ActivityType;
import com.synaptixfit.domain.port.output.insights.InsightsSourcePort;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.Instant;
import java.time.LocalDate;
import java.util.HashSet;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Repository;
import java.time.Clock;
import com.synaptixfit.domain.model.user.BirthDate;

/**
 * Lecturas con {@link JdbcClient} de tablas de otros módulos: {@code entregas_examenes},
 * {@code horarios_academicos}, {@code carga_academica_semanal}, {@code sesiones_focus} (planificador),
 * {@code asignaturas}, {@code materiales_estudio}, {@code test_sessions}, {@code registros_repaso_srs}
 * (académico), {@code perfil_bienestar_usuario} (perfil) y {@code estado_diario_usuario} (entrenamiento).
 * Solo trae filas: qué prácticas cuentan sin duplicar un bloque lo decide {@link PracticeSessions} en
 * los casos de uso.
 */
@Repository
public class InsightsSourceJdbcAdapter implements InsightsSourcePort {

    /** Tipos con coste cognitivo: la definición única del planificador. */
    private static final List<String> COGNITIVE_TYPES = ActivityType.codesWhere(ActivityType::isCognitive);

    private final JdbcClient jdbc;

    private final Clock clock;

    public InsightsSourceJdbcAdapter(JdbcClient jdbc, Clock clock) {
        this.clock = clock;
        this.jdbc = jdbc;
    }

    @Override
    public Optional<Instant> nextPendingExam(UUID userId, Instant from) {
        return jdbc.sql("""
                        SELECT min(fecha_limite) AS proxima FROM entregas_examenes
                        WHERE usuario_id = :u AND esta_completado = false AND tipo = 'examen' AND fecha_limite >= :from
                        """)
                .param("u", userId).param("from", param(from))
                .query((rs, n) -> instant(rs, "proxima")).list().stream()
                .filter(java.util.Objects::nonNull).findFirst();
    }

    @Override
    public List<CompletedStudyBlock> completedStudyBlocks(UUID userId, Instant from, Instant to) {
        return jdbc.sql("""
                        SELECT h.id, h.tipo_actividad, h.hora_inicio, h.hora_fin, h.calorias_quemadas,
                               a.dificultad_percibida
                        FROM horarios_academicos h
                        LEFT JOIN asignaturas a ON a.id = h.asignatura_id
                        WHERE h.usuario_id = :u AND h.completado = true
                          AND h.tipo_actividad IN (:types)
                          AND h.hora_inicio >= :from AND h.hora_inicio < :to
                        ORDER BY h.hora_inicio
                        """)
                .param("u", userId).param("from", param(from)).param("to", param(to))
                .param("types", COGNITIVE_TYPES)
                .query((rs, n) -> new CompletedStudyBlock(uuid(rs, "id"), rs.getString("tipo_actividad"),
                        instant(rs, "hora_inicio"), instant(rs, "hora_fin"), integer(rs, "dificultad_percibida"),
                        decimal(rs, "calorias_quemadas")))
                .list();
    }

    @Override
    public PracticeSessions.Log practiceLog(UUID userId, Instant from, Instant to) {
        List<PracticeSessions.Focus> focus = jdbc.sql("""
                        SELECT f.id, f.duracion_minutos, f.creado_en, a.dificultad_percibida,
                               h.completado AS bloque_completado
                        FROM sesiones_focus f
                        LEFT JOIN asignaturas a ON a.id = f.asignatura_id
                        LEFT JOIN horarios_academicos h ON h.id = f.bloque_id
                        WHERE f.usuario_id = :u AND f.tipo_fase = 'focus' AND f.completada = true
                          AND f.creado_en >= :from AND f.creado_en < :to
                        """)
                .param("u", userId).param("from", param(from)).param("to", param(to))
                .query((rs, n) -> new PracticeSessions.Focus(uuid(rs, "id"), instant(rs, "creado_en"),
                        rs.getInt("duracion_minutos"), integer(rs, "dificultad_percibida"),
                        rs.getBoolean("bloque_completado")))
                .list();
        List<PracticeSessions.TestSession> tests = jdbc.sql("""
                        SELECT t.id, t.iniciado_en, t.completado_en, a.dificultad_percibida
                        FROM test_sessions t
                        JOIN materiales_estudio m ON m.id = t.material_id
                        LEFT JOIN asignaturas a ON a.id = m.asignatura_id
                        WHERE t.usuario_id = :u AND t.status = 'completed'
                          AND t.completado_en >= :from AND t.completado_en < :to
                        """)
                .param("u", userId).param("from", param(from)).param("to", param(to))
                .query((rs, n) -> new PracticeSessions.TestSession(uuid(rs, "id"), instant(rs, "iniciado_en"),
                        instant(rs, "completado_en"), integer(rs, "dificultad_percibida")))
                .list();
        Set<UUID> materialsWithBlock = new HashSet<>(jdbc.sql("""
                        SELECT DISTINCT material_estudio_id FROM horarios_academicos
                        WHERE usuario_id = :u AND completado = true AND material_estudio_id IS NOT NULL
                          AND hora_inicio >= :from AND hora_inicio < :to
                        """)
                .param("u", userId).param("from", param(from)).param("to", param(to))
                .query((rs, n) -> uuid(rs, "material_estudio_id"))
                .list());
        List<PracticeSessions.Review> reviews = jdbc.sql("""
                        SELECT r.id, r.fecha_repaso, m.id AS material_id, a.dificultad_percibida
                        FROM registros_repaso_srs r
                        JOIN materiales_estudio m ON m.id = r.material_estudio_id
                        LEFT JOIN asignaturas a ON a.id = m.asignatura_id
                        WHERE m.usuario_id = :u AND r.fecha_repaso >= :from AND r.fecha_repaso < :to
                        """)
                .param("u", userId).param("from", param(from)).param("to", param(to))
                .query((rs, n) -> new PracticeSessions.Review(uuid(rs, "id"), instant(rs, "fecha_repaso"),
                        uuid(rs, "material_id"), integer(rs, "dificultad_percibida")))
                .list();
        return new PracticeSessions.Log(focus, tests, reviews, materialsWithBlock);
    }

    @Override
    public Optional<BodyProfile> bodyProfile(UUID userId) {
        // Edad calculada con la fecha de nacimiento de la cuenta (ADR 0036); la del perfil solo si no hay fecha.
        return jdbc.sql("SELECT p.peso_kg, p.altura_cm, p.edad, p.sexo, u.fecha_nacimiento"
                        + " FROM perfil_bienestar_usuario p JOIN usuarios u ON u.id = p.usuario_id"
                        + " WHERE p.usuario_id = :u LIMIT 1")
                .param("u", userId)
                .query((rs, n) -> new BodyProfile(rs.getDouble("peso_kg"), rs.getDouble("altura_cm"),
                        BirthDate.effectiveAge(rs.getObject("fecha_nacimiento", LocalDate.class),
                                rs.getObject("edad", Integer.class), LocalDate.now(clock)),
                        sex(rs.getString("sexo"))))
                .optional();
    }

    @Override
    public Optional<WeeklyAcademicLoad> weeklyAcademicLoad(UUID userId, LocalDate weekStart) {
        return jdbc.sql("""
                        SELECT semana_inicio, horas_estudio_planeadas, horas_estudio_reales, evaluaciones_semana,
                               entregas_semana, nivel_estres, horas_sueno_promedio
                        FROM carga_academica_semanal WHERE usuario_id = :u AND semana_inicio = :w
                        ORDER BY actualizado_en DESC LIMIT 1
                        """)
                .param("u", userId).param("w", weekStart)
                .query((rs, n) -> new WeeklyAcademicLoad(date(rs, "semana_inicio"), rs.getInt("horas_estudio_planeadas"),
                        rs.getInt("horas_estudio_reales"), rs.getInt("evaluaciones_semana"), rs.getInt("entregas_semana"),
                        rs.getInt("nivel_estres"), rs.getDouble("horas_sueno_promedio")))
                .optional();
    }

    @Override
    public Optional<DailyCheckIn> checkIn(UUID userId, LocalDate day) {
        return checkIns(userId, day, day).stream().findFirst();
    }

    @Override
    public List<DailyCheckIn> checkIns(UUID userId, LocalDate from, LocalDate to) {
        return jdbc.sql("""
                        SELECT fecha, calidad_sueno, nivel_estres, nivel_energia, dolor_muscular, listo_para_entrenar
                        FROM estado_diario_usuario
                        WHERE usuario_id = :u AND fecha BETWEEN :from AND :to
                        ORDER BY fecha DESC
                        """)
                .param("u", userId).param("from", from).param("to", to)
                .query(InsightsSourceJdbcAdapter::checkIn)
                .list();
    }

    @Override
    public DeadlineCounts deadlineCounts(UUID userId, Instant from, Instant to) {
        return jdbc.sql("""
                        SELECT count(*) AS total, COALESCE(SUM(CASE WHEN esta_completado THEN 1 ELSE 0 END), 0) AS completadas
                        FROM entregas_examenes
                        WHERE usuario_id = :u AND fecha_limite >= :from AND fecha_limite < :to
                        """)
                .param("u", userId).param("from", param(from)).param("to", param(to))
                .query((rs, n) -> new DeadlineCounts(rs.getInt("total"), rs.getInt("completadas")))
                .single();
    }

    private static DailyCheckIn checkIn(ResultSet rs, int n) throws SQLException {
        boolean ready = rs.getBoolean("listo_para_entrenar");
        Boolean readyValue = rs.wasNull() ? null : ready;
        return new DailyCheckIn(date(rs, "fecha"), integer(rs, "calidad_sueno"), integer(rs, "nivel_estres"),
                integer(rs, "nivel_energia"), integer(rs, "dolor_muscular"), readyValue);
    }

    /** 'hombre' / 'mujer'; 'no_binario' y 'prefiero_no_decirlo' usan la constante intermedia. */
    private static BiologicalSex sex(String value) {
        if ("hombre".equals(value)) {
            return BiologicalSex.MALE;
        }
        return "mujer".equals(value) ? BiologicalSex.FEMALE : BiologicalSex.OTHER;
    }
}
