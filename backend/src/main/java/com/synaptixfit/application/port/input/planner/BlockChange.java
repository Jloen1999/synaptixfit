package com.synaptixfit.application.port.input.planner;

import com.synaptixfit.domain.model.planner.CalendarBlock;
import java.util.List;

/**
 * Resultado de crear o cambiar de horario un bloque: el bloque, los bloques con los que se solapa
 * (aviso, no error) y cuántas copias semanales se crearon con «Repetir cada semana».
 */
public record BlockChange(CalendarBlock block, List<CalendarBlock> conflicts, int weeklyCopies) {

    public BlockChange {
        conflicts = List.copyOf(conflicts);
    }

    public BlockChange(CalendarBlock block, List<CalendarBlock> conflicts) {
        this(block, conflicts, 0);
    }
}
