package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.dashboard;

import static com.synaptixfit.infrastructure.adapter.output.persistence.adapter.insights.JdbcRows.instant;
import static com.synaptixfit.infrastructure.adapter.output.persistence.adapter.insights.JdbcRows.param;
import static com.synaptixfit.infrastructure.adapter.output.persistence.adapter.insights.JdbcRows.uuid;

import com.synaptixfit.domain.model.dashboard.DashboardReadModels.CalendarBlock;
import com.synaptixfit.domain.model.dashboard.DashboardReadModels.Deadline;
import com.synaptixfit.domain.model.dashboard.DashboardReadModels.NextTrainingDay;
import com.synaptixfit.domain.model.dashboard.DashboardReadModels.TrainingTotals;
import com.synaptixfit.domain.port.output.dashboard.DashboardReadPort;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Repository;

/**
 * Lecturas con {@link JdbcClient} para el inicio: {@code sesiones_registradas},
 * {@code plan_entrenamiento_semanal}, {@code rutinas}/{@code semanas_rutina}/{@code dias_rutina}
 * (entrenamiento), {@code horarios_academicos}, {@code entregas_examenes} (planificador),
 * {@code asignaturas} (académico). Solo acceso a datos: los retos y su progreso los da el módulo de retos.
 */
@Repository
public class DashboardJdbcAdapter implements DashboardReadPort {

    private final JdbcClient jdbc;

    public DashboardJdbcAdapter(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    @Override
    public TrainingTotals trainingTotals(UUID userId, Instant from, Instant to) {
        return jdbc.sql("""
                        SELECT count(*) AS sesiones, coalesce(sum(duracion_minutos), 0) AS minutos,
                               coalesce(sum(calorias_quemadas), 0) AS calorias
                        FROM sesiones_registradas
                        WHERE usuario_id = :u AND completada_en >= :from AND completada_en < :to
                        """)
                .param("u", userId).param("from", param(from)).param("to", param(to))
                .query((rs, n) -> new TrainingTotals(rs.getInt("sesiones"), rs.getInt("minutos"), rs.getDouble("calorias")))
                .single();
    }

    @Override
    public Optional<Integer> plannedWeeklySessions(UUID userId, LocalDate weekStart) {
        return jdbc.sql("""
                        SELECT sesiones_planificadas FROM plan_entrenamiento_semanal
                        WHERE usuario_id = :u AND estado = 'activo' AND semana_inicio = :week
                        LIMIT 1
                        """)
                .param("u", userId).param("week", weekStart).query(Integer.class).optional();
    }

    @Override
    public List<CalendarBlock> calendarBlocks(UUID userId, Instant from, Instant to) {
        return jdbc.sql("""
                        SELECT h.id, h.tipo_actividad, h.hora_inicio, h.hora_fin, h.completado, h.temas,
                               a.nombre AS asignatura
                        FROM horarios_academicos h
                        LEFT JOIN asignaturas a ON a.id = h.asignatura_id
                        WHERE h.usuario_id = :u AND h.hora_inicio >= :from AND h.hora_inicio < :to
                        ORDER BY h.hora_inicio
                        """)
                .param("u", userId).param("from", param(from)).param("to", param(to))
                .query((rs, n) -> new CalendarBlock(uuid(rs, "id"), rs.getString("tipo_actividad"),
                        instant(rs, "hora_inicio"), instant(rs, "hora_fin"), rs.getBoolean("completado"),
                        rs.getString("asignatura"), rs.getString("temas")))
                .list();
    }

    @Override
    public List<Deadline> deadlines(UUID userId, Instant from, Instant to) {
        return jdbc.sql("""
                        SELECT e.id, e.titulo, e.tipo, e.fecha_limite, e.esta_completado, a.nombre AS asignatura
                        FROM entregas_examenes e
                        LEFT JOIN asignaturas a ON a.id = e.asignatura_id
                        WHERE e.usuario_id = :u AND e.fecha_limite >= :from AND e.fecha_limite < :to
                        ORDER BY e.fecha_limite
                        """)
                .param("u", userId).param("from", param(from)).param("to", param(to))
                .query((rs, n) -> new Deadline(uuid(rs, "id"), rs.getString("titulo"), rs.getString("tipo"),
                        instant(rs, "fecha_limite"), rs.getBoolean("esta_completado"), rs.getString("asignatura")))
                .list();
    }

    @Override
    public Optional<NextTrainingDay> nextTrainingDay(UUID userId) {
        return jdbc.sql("""
                        SELECT r.id AS rutina_id, r.nombre AS rutina, s.id AS semana_id, s.numero_semana,
                               d.id AS dia_id, d.numero_dia, d.nombre AS dia, d.estado,
                               (SELECT MAX(t.creado_en) FROM sesiones_registradas t
                                 WHERE t.dia_id = d.id AND t.completada_en IS NULL) AS sesion_abierta
                        FROM rutinas r
                        JOIN semanas_rutina s ON s.rutina_id = r.id
                        JOIN dias_rutina d ON d.semana_id = s.id
                        WHERE r.usuario_id = :u AND r.estado = 'activo' AND r.eliminado_en IS NULL
                          AND d.estado <> 'completado'
                        ORDER BY r.creado_en DESC, s.numero_semana, d.numero_dia
                        LIMIT 1
                        """)
                .param("u", userId)
                .query((rs, n) -> new NextTrainingDay(uuid(rs, "rutina_id"), rs.getString("rutina"),
                        uuid(rs, "semana_id"), rs.getInt("numero_semana"), uuid(rs, "dia_id"), rs.getInt("numero_dia"),
                        rs.getString("dia"), rs.getString("estado"), instant(rs, "sesion_abierta")))
                .optional();
    }

    @Override
    public Optional<Instant> lastTrainingSession(UUID userId) {
        return jdbc.sql("SELECT max(completada_en) AS ultima FROM sesiones_registradas WHERE usuario_id = :u")
                .param("u", userId).query((rs, n) -> instant(rs, "ultima")).list().stream()
                .filter(java.util.Objects::nonNull).findFirst();
    }
}
