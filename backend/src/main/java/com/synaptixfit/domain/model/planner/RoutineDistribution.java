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
 * Reparte en el calendario los días que le quedan a una rutina (los ya hechos, saltados o sin
 * ejercicios no se colocan), en orden: semana 1 día 1, semana 1 día 2…
 *
 * <p>Sin días de la semana elegidos, cada día va al siguiente con su día de la semana preferido
 * ({@code dayNumber}, 1 = lunes): así el calendario coincide con lo que propone la rutina. Con días
 * elegidos, cada día ocupa la siguiente fecha cuyo día de la semana esté entre ellos. Se intenta a la
 * hora preferida; si esa franja choca con otro bloque se usa el primer hueco libre del día (hasta las
 * 22:00) y, si no lo hay, se pasa a la siguiente fecha válida. Nunca se coloca nada en el pasado.
 *
 * <p>Título: «Semana 2 · Tirón» (o el nombre de la rutina si el día no tiene nombre propio). El día de
 * la semana no se repite: ya lo dice la fecha del bloque.
 */
public final class RoutineDistribution {

    static final LocalTime DAY_LIMIT = LocalTime.of(22, 0);
    private static final int MAX_DAYS_AHEAD = 366;

    private RoutineDistribution() {
    }

    /**
     * @param weekdays días de la semana elegidos (1-7); vacío para usar el preferido de cada día
     */
    public static List<CalendarBlock> distribute(UUID userId, RoutineRef routine, Set<Integer> weekdays,
                                                 LocalDate startDate, LocalTime preferredStart, int durationMinutes,
                                                 List<CalendarBlock> existing, PlannerZone zone, Instant now,
                                                 Supplier<UUID> ids) {
        List<RoutineRef.Day> remaining = routine.days().stream().filter(RoutineRef.Day::pending).toList();
        if (remaining.isEmpty()) {
            throw new RoutineWithoutDaysException();
        }
        if (weekdays.stream().anyMatch(d -> d < 1 || d > 7)) {
            throw new FieldValidationException("weekdays", "OUT_OF_RANGE", "weekdays must contain values 1-7");
        }
        List<CalendarBlock> busy = new ArrayList<>(existing);
        List<CalendarBlock> created = new ArrayList<>();
        LocalDate cursor = startDate.isBefore(zone.today(now)) ? zone.today(now) : startDate;
        LocalDate limit = cursor.plusDays(MAX_DAYS_AHEAD);
        for (RoutineRef.Day day : remaining) {
            Set<Integer> allowed = weekdays.isEmpty() ? Set.of(day.dayNumber()) : weekdays;
            Optional<TimeRange> slot = Optional.empty();
            while (slot.isEmpty() && !cursor.isAfter(limit)) {
                if (allowed.contains(cursor.getDayOfWeek().getValue())) {
                    slot = slotOn(cursor, preferredStart, durationMinutes, busy, zone, now);
                }
                if (slot.isEmpty()) {
                    cursor = cursor.plusDays(1);
                }
            }
            if (slot.isEmpty()) {
                break;
            }
            CalendarBlock block = CalendarBlock.builder()
                    .id(ids.get())
                    .userId(userId)
                    .range(slot.get())
                    .dayOfWeek(cursor.getDayOfWeek().getValue())
                    .type(ActivityType.SPORT)
                    .details(new CalendarBlock.Details(null, title(routine, day), null, Priority.MEDIUM, false, null,
                            routine.id(), day.weekId(), day.id(), null, null, null))
                    .createdAt(now)
                    .build();
            created.add(block);
            busy.add(block);
            cursor = cursor.plusDays(1);
        }
        return created;
    }

    /** «Semana 2 · Tirón»; sin nombre propio, el de la rutina. */
    public static String title(RoutineRef routine, RoutineRef.Day day) {
        String name = day.name() == null || day.name().isBlank() ? routine.name() : day.name();
        return "Semana " + day.weekNumber() + " · " + name;
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
