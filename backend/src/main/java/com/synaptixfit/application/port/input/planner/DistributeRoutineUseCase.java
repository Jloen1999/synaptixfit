package com.synaptixfit.application.port.input.planner;

import com.synaptixfit.domain.model.planner.CalendarBlock;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;
import java.util.Set;
import java.util.UUID;

/**
 * Reparte los días de una rutina en el calendario como bloques de deporte vinculados a su semana y
 * día, en los días de la semana elegidos desde una fecha de inicio, sin pisar otros bloques.
 */
public interface DistributeRoutineUseCase {

    /**
     * @param weekdays        días de la semana elegidos (1 = lunes … 7 = domingo)
     * @param preferredStart  hora preferida (por defecto 08:00)
     * @param durationMinutes duración de cada sesión (30-240)
     */
    record Command(UUID userId, UUID routineId, Set<Integer> weekdays, LocalDate startDate, LocalTime preferredStart,
                   int durationMinutes) {
    }

    List<CalendarBlock> distribute(Command command);
}
