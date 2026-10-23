package com.synaptixfit.domain.model.planner;

import com.synaptixfit.domain.exception.FieldValidationException;
import com.synaptixfit.domain.exception.planner.RoutineWithoutDaysException;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.function.Supplier;

/**
 * Reparte los días de una rutina en el calendario.
 *
 * <p>Cada día de la rutina (semana 1 día 1, semana 1 día 2…) ocupa la siguiente fecha, desde la
 * fecha de inicio, cuyo día de la semana esté entre los elegidos. Se intenta a la hora preferida; si
 * esa franja choca con otro bloque se usa el primer hueco libre del día (hasta las 22:00) y, si no
 * lo hay, se pasa a la siguiente fecha elegible. Nunca se coloca nada en el pasado.
 */
public final class RoutineDistribution {

    static final LocalTime DAY_LIMIT = LocalTime.of(22, 0);
    private static final int MAX_DAYS_AHEAD = 366;

    private RoutineDistribution() {
    }

    public static List<CalendarBlock> distribute(UUID userId, RoutineRef routine, Set<Integer> weekdays,
                                                 LocalDate startDate, LocalTime preferredStart, int durationMinutes,
                                                 List<CalendarBlock> existing, PlannerZone zone, Instant now,
                                                 Supplier<UUID> ids) {
        if (routine.days().isEmpty()) {
            throw new RoutineWithoutDaysException();
        }
        if (weekdays.isEmpty() || weekdays.stream().anyMatch(d -> d < 1 || d > 7)) {
            throw new FieldValidationException("weekdays", "OUT_OF_RANGE", "weekdays must contain values 1-7");
        }
        List<CalendarBlock> busy = new ArrayList<>(existing);
        List<CalendarBlock> created = new ArrayList<>();
        LocalDate cursor = startDate.isBefore(zone.today(now)) ? zone.today(now) : startDate;
        LocalDate limit = cursor.plusDays(MAX_DAYS_AHEAD);
        for (RoutineRef.Day day : routine.days()) {
            Optional<TimeRange> slot = Optional.empty();
            while (slot.isEmpty() && !cursor.isAfter(limit)) {
                if (weekdays.contains(cursor.getDayOfWeek().getValue())) {
                    slot = slotOn(cursor, preferredStart, durationMinutes, busy, zone, now);
                }
                if (slot.isEmpty()) {
                    cursor = cursor.plusDays(1);
                }
            }
            if (slot.isEmpty()) {
                break;
            }
            String title = day.name() == null || day.name().isBlank()
                    ? "Día " + (created.size() + 1) : day.name();
            CalendarBlock block = CalendarBlock.builder()
                    .id(ids.get())
                    .userId(userId)
                    .range(slot.get())
                    .dayOfWeek(cursor.getDayOfWeek().getValue())
                    .type(ActivityType.SPORT)
                    .details(new CalendarBlock.Details(null, title, null, Priority.MEDIUM, false, null,
                            routine.id(), day.weekId(), day.id(), null, null, null))
                    .createdAt(now)
                    .build();
            created.add(block);
            busy.add(block);
            cursor = cursor.plusDays(1);
        }
        return created;
    }

    private static Optional<TimeRange> slotOn(LocalDate date, LocalTime preferred, int minutes,
                                              List<CalendarBlock> busy, PlannerZone zone, Instant now) {
        Instant from = zone.at(date, preferred);
        if (from.isBefore(now)) {
            from = now;
        }
        return ScheduleConflicts.firstFreeSlot(minutes, from, zone.at(date, DAY_LIMIT), busy);
    }
}
