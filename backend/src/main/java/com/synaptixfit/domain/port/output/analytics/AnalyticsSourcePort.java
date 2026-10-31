package com.synaptixfit.domain.port.output.analytics;

import com.synaptixfit.domain.model.analytics.StudyWeekSummary;
import com.synaptixfit.domain.model.analytics.WeeklyStudyLoad;
import com.synaptixfit.domain.model.analytics.WeeklyTrainingMetric.CompletedSession;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/**
 * Datos de la analítica: sesiones de entrenamiento completadas (filas sin agrupar; las semanas las
 * calcula {@code WeeklyTrainingMetric.byWeek} en el caso de uso) y carga de estudio semanal del
 * planificador, en orden ascendente.
 */
public interface AnalyticsSourcePort {

    /** Sesiones completadas desde {@code from} (incluido). */
    List<CompletedSession> completedTrainingSessions(UUID userId, Instant from);

    List<WeeklyStudyLoad> weeklyStudyLoads(UUID userId, LocalDate fromWeek);

    /**
     * Recuentos de estudio entre {@code from} (incluido) y {@code to} (excluido): fases de
     * concentración completadas, bloques de los tipos {@code studyBlockCodes} que ya debían estar
     * hechos en {@code now} (o ya completados), repasos, simulacros
     * terminados y materiales con el repaso pendiente en {@code now}. Los días del Pomodoro
     * ({@code fecha}) van de {@code fromDay} a {@code toDay} (excluido).
     */
    StudyWeekSummary.Counts studyCounts(UUID userId, Instant from, Instant to, LocalDate fromDay, LocalDate toDay,
                                        List<String> studyBlockCodes, Instant now);
}
