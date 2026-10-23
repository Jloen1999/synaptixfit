package com.synaptixfit.application.port.input.insights;

import java.time.LocalDate;
import java.util.UUID;

/**
 * Registra (sesión completada) o borra (sesión desmarcada) la carga física de una sesión y
 * recalcula el ACWR. Idempotente: repetir el mismo evento no duplica registros.
 */
public interface RecordTrainingLoadUseCase {

    record Command(UUID userId, UUID sessionId, LocalDate date, int rpe, int durationMinutes, boolean completed) {}

    void recordTrainingLoad(Command command);
}
