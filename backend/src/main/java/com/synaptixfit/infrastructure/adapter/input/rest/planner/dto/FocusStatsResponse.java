package com.synaptixfit.infrastructure.adapter.input.rest.planner.dto;

import com.synaptixfit.domain.model.planner.FocusStats;
import java.time.LocalDate;
import java.util.List;

/** Estadísticas Pomodoro: hoy, la semana (lunes a domingo) y el detalle por día. */
public record FocusStatsResponse(Totals today, Totals week, List<Day> days) {

    /** Totales de fases completadas. */
    public record Totals(int focusMinutes, int breakMinutes, int focusCycles, int sessions) {

        static Totals from(FocusStats.Totals t) {
            return new Totals(t.focusMinutes(), t.breakMinutes(), t.focusCycles(), t.sessions());
        }
    }

    /** Totales de un día. */
    public record Day(LocalDate date, Totals totals) {
    }

    public static FocusStatsResponse from(FocusStats s) {
        return new FocusStatsResponse(Totals.from(s.today()), Totals.from(s.week()),
                s.days().stream().map(d -> new Day(d.date(), Totals.from(d.totals()))).toList());
    }
}
