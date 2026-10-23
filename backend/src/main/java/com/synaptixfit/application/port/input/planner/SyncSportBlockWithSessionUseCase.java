package com.synaptixfit.application.port.input.planner;

import java.time.LocalDate;
import java.util.UUID;

/**
 * Una sesión de entrenamiento de un día de rutina se ha completado o desmarcado: el bloque de deporte
 * de ese día de rutina y esa fecha sigue su estado. No da ni resta XP de bloque (la XP es de la
 * sesión). Idempotente (lo invoca el oyente de {@code TrainingSessionCompletionChanged}).
 */
public interface SyncSportBlockWithSessionUseCase {

    void syncSportBlock(UUID userId, UUID routineDayId, LocalDate date, boolean completed);
}
