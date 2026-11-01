package com.synaptixfit.domain.model.training;

import java.time.LocalDate;
import java.util.UUID;

/**
 * Próximo día de entrenamiento de la rutina en curso, calculado por {@link RoutineSchedule}.
 *
 * @param status         {@code IN_PROGRESS} si hay una sesión en curso de ese día; si no, {@code PENDING}
 * @param scheduledDate  cuándo toca (bloque del calendario o día de la semana preferido)
 * @param overdue        la fecha prevista ya pasó
 * @param sessionOfWeek  posición del día entre los entrenables de su semana («sesión 2 de 3»)
 * @param sessionsInWeek días entrenables de esa semana
 * @param staleSessionId sesión abandonada de ese día que hay que terminar o descartar antes (o null)
 */
public record PendingDay(Routine routine, RoutineWeek week, RoutineDay day, ProgressStatus status,
                         LocalDate scheduledDate, boolean overdue, int sessionOfWeek, int sessionsInWeek,
                         UUID staleSessionId) {
}
