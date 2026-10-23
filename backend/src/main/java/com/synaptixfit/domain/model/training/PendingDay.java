package com.synaptixfit.domain.model.training;

/** Próximo día de entrenamiento pendiente de la rutina activa. */
public record PendingDay(Routine routine, RoutineWeek week, RoutineDay day) {
}
