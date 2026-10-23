package com.synaptixfit.application.port.input.planner;

import java.time.Instant;
import java.util.UUID;

/**
 * Crea un bloque en el calendario. No se permite en el pasado. Los bloques EXAM y DELIVERY sin
 * entrega vinculada crean su entrega/examen (fecha límite = inicio del bloque en un examen, fin en
 * una entrega) y quedan vinculados a ella.
 */
public interface CreateCalendarBlockUseCase {

    /**
     * @param fixed       bloque fijo (p. ej. una clase recurrente): no se puede mover ni redimensionar
     * @param repeatWeeks semanas siguientes en las que se repite a la misma hora (0: ninguna; como
     *                    mucho {@code CalendarBlock.MAX_WEEKLY_REPEATS}; se ignora en exámenes y entregas)
     */
    record Command(UUID userId, Instant start, Instant end, boolean fixed, BlockDetailsInput details,
                   int repeatWeeks) {

        public Command(UUID userId, Instant start, Instant end, boolean fixed, BlockDetailsInput details) {
            this(userId, start, end, fixed, details, 0);
        }
    }

    BlockChange createBlock(Command command);
}
