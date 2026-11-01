package com.synaptixfit.application.port.input.planner;

import com.synaptixfit.domain.model.planner.CalendarBlock;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;
import java.util.Set;
import java.util.UUID;

/**
 * Reparte los días que le quedan a una rutina en el calendario como bloques de deporte vinculados a
 * su semana y día, desde una fecha de inicio y sin pisar otros bloques: en el día de la semana
 * preferido de cada día o en los días de la semana elegidos. Sustituye los bloques futuros pendientes
 * que ya tuviera esa rutina.
 */
public interface DistributeRoutineUseCase {

    /**
     * @param weekdays        días de la semana elegidos (1 = lunes … 7 = domingo); vacío o nulo para usar
     *                        el día de la semana preferido de cada día de la rutina
     * @param preferredStart  hora preferida (por defecto 08:00)
     * @param durationMinutes duración de cada sesión (30-240)
     */
    record Command(UUID userId, UUID routineId, Set<Integer> weekdays, LocalDate startDate, LocalTime preferredStart,
                   int durationMinutes) {
    }

    List<CalendarBlock> distribute(Command command);
}
