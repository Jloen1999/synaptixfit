package com.synaptixfit.application.port.input.insights;

import java.time.LocalDate;
import java.util.UUID;

/**
 * Registra o retira la carga física de un bloque de deporte del calendario que no es una sesión de
 * rutina (p. ej. «Fútbol 90 min»), para que cuente en el ACWR y la fatiga. Idempotente por bloque.
 */
public interface SyncSportBlockLoadUseCase {

    /** @param effort esfuerzo percibido 1-10; null toma el moderado por defecto */
    record Command(UUID userId, UUID blockId, LocalDate date, Integer effort, int durationMinutes, boolean completed) {}

    void syncSportBlockLoad(Command command);
}
