package com.synaptixfit.application.port.input.planner;

import java.util.UUID;

/**
 * Lleva un bloque (normalmente uno que se quedó sin hacer) al primer hueco libre de su misma
 * duración desde ahora, entre las 8:00 y las 22:00 de los próximos 7 días.
 */
public interface RescheduleBlockToNextFreeSlotUseCase {

    BlockChange rescheduleToNextFreeSlot(UUID userId, UUID blockId);
}
