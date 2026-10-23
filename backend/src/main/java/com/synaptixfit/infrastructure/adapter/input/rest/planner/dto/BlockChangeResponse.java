package com.synaptixfit.infrastructure.adapter.input.rest.planner.dto;

import com.synaptixfit.application.port.input.planner.BlockChange;
import java.util.List;

/** Bloque creado o movido, los bloques con los que se solapa (aviso) y las copias semanales creadas. */
public record BlockChangeResponse(CalendarBlockResponse block, List<CalendarBlockResponse> conflicts,
                                  int weeklyCopies) {

    public static BlockChangeResponse from(BlockChange change) {
        return new BlockChangeResponse(CalendarBlockResponse.from(change.block()),
                change.conflicts().stream().map(CalendarBlockResponse::from).toList(), change.weeklyCopies());
    }
}
