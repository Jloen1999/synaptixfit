package com.synaptixfit.domain.model.planner;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Estadísticas de concentración: hoy, la semana y el detalle por día.
 */
public record FocusStats(Totals today, Totals week, List<DayTotals> days) {

    /** Totales de un periodo. Solo cuentan las fases completadas. */
    public record Totals(int focusMinutes, int breakMinutes, int focusCycles, int sessions) {
    }

    /** Totales de un día. */
    public record DayTotals(LocalDate date, Totals totals) {
    }

    /** Agrega los registros de la semana [{@code weekStart}, +6] y del día {@code today}. */
    public static FocusStats of(List<FocusSession> sessions, LocalDate weekStart, LocalDate today) {
        Map<LocalDate, List<FocusSession>> byDay = new LinkedHashMap<>();
        for (int i = 0; i < 7; i++) {
            byDay.put(weekStart.plusDays(i), new ArrayList<>());
        }
        for (FocusSession s : sessions) {
            List<FocusSession> bucket = byDay.get(s.date());
            if (bucket != null) {
                bucket.add(s);
            }
        }
        List<DayTotals> days = byDay.entrySet().stream()
                .map(e -> new DayTotals(e.getKey(), totals(e.getValue()))).toList();
        List<FocusSession> todays = sessions.stream().filter(s -> s.date().equals(today)).toList();
        List<FocusSession> week = byDay.values().stream().flatMap(List::stream).toList();
        return new FocusStats(totals(todays), totals(week), days);
    }

    private static Totals totals(List<FocusSession> sessions) {
        int focus = 0;
        int rest = 0;
        int cycles = 0;
        int count = 0;
        for (FocusSession s : sessions) {
            if (!s.completed()) {
                continue;
            }
            count++;
            if (s.phase() == FocusSession.FocusPhase.FOCUS) {
                focus += s.durationMinutes();
                cycles += s.cycles();
            } else {
                rest += s.durationMinutes();
            }
        }
        return new Totals(focus, rest, cycles, count);
    }
}
