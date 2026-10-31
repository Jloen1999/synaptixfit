package com.synaptixfit.domain.port.output.dashboard;

import com.synaptixfit.domain.model.dashboard.DashboardReadModels.CalendarBlock;
import com.synaptixfit.domain.model.dashboard.DashboardReadModels.Deadline;
import com.synaptixfit.domain.model.dashboard.DashboardReadModels.NextTrainingDay;
import com.synaptixfit.domain.model.dashboard.DashboardReadModels.TrainingTotals;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Lecturas de otros módulos para el resumen del inicio. Solo lectura y solo datos: los retos activos
 * no se leen aquí, sino con el caso de uso del módulo de retos, para que el progreso lo calcule
 * {@code Challenge.progress()} y no una consulta SQL.
 */
public interface DashboardReadPort {

    /** Sesiones completadas en [from, to). */
    TrainingTotals trainingTotals(UUID userId, Instant from, Instant to);

    /** Sesiones planificadas del plan de entrenamiento semanal activo. */
    /** Sesiones planificadas en el plan semanal activo de la semana que empieza en {@code weekStart}. */
    Optional<Integer> plannedWeeklySessions(UUID userId, LocalDate weekStart);

    /** Bloques del calendario que empiezan en [from, to), ordenados por inicio. */
    List<CalendarBlock> calendarBlocks(UUID userId, Instant from, Instant to);

    /** Entregas y exámenes con fecha límite en [from, to), ordenados por fecha. */
    List<Deadline> deadlines(UUID userId, Instant from, Instant to);

    /**
     * Próximo día pendiente de la rutina activa, con el inicio de su sesión abierta más reciente
     * (el estado efectivo lo decide {@code NextTrainingDay.effective}).
     */
    Optional<NextTrainingDay> nextTrainingDay(UUID userId);

    Optional<Instant> lastTrainingSession(UUID userId);
}
