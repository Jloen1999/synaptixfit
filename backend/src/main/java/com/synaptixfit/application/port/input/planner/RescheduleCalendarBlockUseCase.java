package com.synaptixfit.application.port.input.planner;

import java.time.Instant;
import java.util.UUID;

/**
 * Mueve o redimensiona un bloque. Con solo {@code start} se mueve conservando la duración; con solo
 * {@code end} se redimensiona; con ambos se fijan los dos. Los bloques fijos, inamovibles o
 * completados no cambian de horario y nada se mueve al pasado.
 */
public interface RescheduleCalendarBlockUseCase {

    record Command(UUID userId, UUID blockId, Instant start, Instant end) {
    }

    BlockChange reschedule(Command command);
}
