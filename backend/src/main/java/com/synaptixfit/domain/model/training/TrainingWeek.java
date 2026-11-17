package com.synaptixfit.domain.model.training;

import com.synaptixfit.domain.model.shared.Guard;
import java.time.DayOfWeek;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.temporal.TemporalAdjusters;
import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * La semana de entreno de un vistazo (de lunes a domingo): qué días se entrenó, cuáles tocan aún y cuál es hoy.
 * La pinta Gimnasio con siete puntos (ADR 0055); los días previstos salen de {@link RoutineSchedule#upcoming}.
 *
 * @param done  días de la semana con al menos un entreno terminado
 * @param total esos días más los que aún tocan («2 de 4»)
 */
public record TrainingWeek(List<Day> days, int done, int total) {

    /** Qué pasa ese día: ya se entrenó, toca entrenar o no hay nada. */
    public enum DayState { DONE, PLANNED, FREE }

    /**
     * @param sessionId entreno terminado de ese día (el último si hubo varios), para abrirlo; nulo si no se entrenó
     */
    public record Day(LocalDate date, DayState state, boolean today, UUID sessionId) {

        public Day {
            Guard.notNull(date, "date");
            Guard.notNull(state, "state");
        }
    }

    public TrainingWeek {
        days = List.copyOf(Guard.notNull(days, "days"));
        Guard.range(days.size(), "days", 7, 7);
        Guard.range(done, "done", 0, 7);
        Guard.range(total, "total", done, 7);
    }

    /** Lunes de la semana de {@code date}. */
    public static LocalDate mondayOf(LocalDate date) {
        return date.with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY));
    }

    /**
     * @param completedAt cuándo se terminó cada sesión (id → instante); cada una cuenta en su día de {@code zone} y,
     *                    si un día hubo varias, se abre la última
     * @param planned     fechas en las que toca entrenar. Las anteriores a hoy no cuentan: lo que no se hizo ya no
     *                    «toca» ese día, pasa al siguiente. Un día con un entreno hecho cuenta como hecho aunque
     *                    tocara otro (p. ej. una sesión libre el día de la rutina): ese día ya se entrenó
     */
    public static TrainingWeek of(LocalDate today, ZoneId zone, Map<UUID, Instant> completedAt,
                                  Collection<LocalDate> planned) {
        Guard.notNull(today, "today");
        Guard.notNull(zone, "zone");
        Guard.notNull(completedAt, "completedAt");
        Guard.notNull(planned, "planned");
        Map<LocalDate, UUID> lastOfDay = new HashMap<>();
        Map<LocalDate, Instant> lastAt = new HashMap<>();
        completedAt.forEach((id, at) -> {
            LocalDate day = LocalDate.ofInstant(at, zone);
            if (!lastAt.containsKey(day) || at.isAfter(lastAt.get(day))) {
                lastAt.put(day, at);
                lastOfDay.put(day, id);
            }
        });
        LocalDate monday = mondayOf(today);
        List<Day> days = new ArrayList<>();
        int done = 0;
        int pending = 0;
        for (int i = 0; i < 7; i++) {
            LocalDate date = monday.plusDays(i);
            UUID session = lastOfDay.get(date);
            DayState state;
            if (session != null) {
                state = DayState.DONE;
                done++;
            } else if (!date.isBefore(today) && planned.contains(date)) {
                state = DayState.PLANNED;
                pending++;
            } else {
                state = DayState.FREE;
            }
            days.add(new Day(date, state, date.equals(today), session));
        }
        return new TrainingWeek(days, done, done + pending);
    }

    public LocalDate monday() {
        return days.get(0).date();
    }
}
