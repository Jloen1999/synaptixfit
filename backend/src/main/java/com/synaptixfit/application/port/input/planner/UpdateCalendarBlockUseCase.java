package com.synaptixfit.application.port.input.planner;

import com.synaptixfit.domain.model.planner.CalendarBlock;
import java.util.UUID;

/** Sustituye los datos editables de un bloque (tipo, asignatura, temas, vínculos…), sin tocar su horario. */
public interface UpdateCalendarBlockUseCase {

    record Command(UUID userId, UUID blockId, BlockDetailsInput details) {
    }

    CalendarBlock updateBlock(Command command);
}
