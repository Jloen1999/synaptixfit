package com.synaptixfit.application.port.input.planner;

import com.synaptixfit.domain.model.planner.CalendarBlock;
import java.util.UUID;

/** Un bloque del usuario. */
public interface GetCalendarBlockUseCase {

    CalendarBlock getBlock(UUID userId, UUID blockId);
}
