package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.dashboard;

import static com.synaptixfit.infrastructure.adapter.output.persistence.adapter.insights.JdbcRows.instant;
import static com.synaptixfit.infrastructure.adapter.output.persistence.adapter.insights.JdbcRows.param;
import static com.synaptixfit.infrastructure.adapter.output.persistence.adapter.insights.JdbcRows.uuid;

import com.synaptixfit.domain.model.dashboard.DashboardReadModels.CalendarBlock;
import com.synaptixfit.domain.model.dashboard.DashboardReadModels.Deadline;
import com.synaptixfit.domain.model.dashboard.DashboardReadModels.TrainingTotals;
import com.synaptixfit.domain.port.output.dashboard.DashboardReadPort;
import com.synaptixfit.infrastructure.adapter.output.persistence.adapter.CompletedWorkoutsSql;
import com.synaptixfit.infrastructure.adapter.output.persistence.mapper.planner.PlannerPersistenceMapper;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Repository;

/**
 * Lecturas con {@link JdbcClient} para el inicio: los entrenos hechos ({@link CompletedWorkoutsSql}: sesiones,
 * actividades apuntadas, carreras y su carga), {@code plan_entrenamiento_semanal} (entrenamiento), {@code horarios_academicos}, {@code entregas_examenes} (planificador),
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
        // Entrenos hechos con la definición única (CompletedWorkoutsSql), igual que Progreso: sesiones de gimnasio y
        // actividades hechas (carreras GPS, partidos, apuntadas a mano), con sus minutos reales y sus kcal.
        return jdbc.sql("""
                        SELECT count(*) AS sesiones, coalesce(sum(e.minutos), 0) AS minutos,
                               coalesce(sum(e.kcal), 0) AS calorias
                        FROM %s e
                        WHERE e.usuario_id = :u AND e.terminado_en >= :from AND e.terminado_en < :to
                        """.formatted(CompletedWorkoutsSql.TABLE))
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
                               a.nombre AS asignatura, h.rutina_id, h.dia_rutina_id, h.hito_id, h.ubicacion,
                               a.aula, a.docente
                        FROM horarios_academicos h
                        LEFT JOIN asignaturas a ON a.id = h.asignatura_id
                        WHERE h.usuario_id = :u AND h.hora_inicio >= :from AND h.hora_inicio < :to
                        ORDER BY h.hora_inicio
                        """)
                .param("u", userId).param("from", param(from)).param("to", param(to))
                .query((rs, n) -> new CalendarBlock(uuid(rs, "id"), rs.getString("tipo_actividad"),
                        instant(rs, "hora_inicio"), instant(rs, "hora_fin"), rs.getBoolean("completado"),
                        rs.getString("asignatura"), rs.getString("temas"), uuid(rs, "rutina_id"),
                        uuid(rs, "dia_rutina_id"), uuid(rs, "hito_id"), rs.getString("ubicacion"),
                        rs.getString("aula"), rs.getString("docente")))
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
                        instant(rs, "fecha_limite"), rs.getBoolean("esta_completado"), rs.getString("asignatura"),
                        PlannerPersistenceMapper.deadlineTypeToDomain(rs.getString("tipo"))))
                .list();
    }

    @Override
    public Optional<Instant> lastTrainingSession(UUID userId) {
        return jdbc.sql("""
                        SELECT max(e.terminado_en) AS ultima FROM %s e WHERE e.usuario_id = :u
                        """.formatted(CompletedWorkoutsSql.TABLE))
                .param("u", userId).query((rs, n) -> instant(rs, "ultima")).list().stream()
                .filter(java.util.Objects::nonNull).findFirst();
    }
}
