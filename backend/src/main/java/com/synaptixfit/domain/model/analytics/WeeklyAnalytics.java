package com.synaptixfit.domain.model.analytics;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Serie semanal completa del periodo (una entrada por semana, con ceros en las semanas sin
 * entrenar, en orden ascendente) y sus totales.
 *
 * @param averageRpe RPE medio del periodo ponderado por sesiones; null sin sesiones
 */
public record WeeklyAnalytics(AnalyticsPeriod period, LocalDate fromWeek, LocalDate toWeek,
                              List<WeeklyTrainingMetric> weeks, int totalSessions, int totalMinutes,
                              int totalCalories, Double averageRpe) {

    public WeeklyAnalytics {
        weeks = List.copyOf(weeks);
    }

    /** Primera semana (lunes) del periodo que termina en {@code currentWeek}. */
    public static LocalDate fromWeek(AnalyticsPeriod period, LocalDate currentWeek) {
        return currentWeek.minusWeeks(period.weeks() - 1L);
    }

    public static WeeklyAnalytics of(AnalyticsPeriod period, LocalDate currentWeek, List<WeeklyTrainingMetric> raw) {
        LocalDate from = fromWeek(period, currentWeek);
        Map<LocalDate, WeeklyTrainingMetric> byWeek = new HashMap<>();
        raw.forEach(m -> byWeek.put(m.weekStart(), m));
        List<WeeklyTrainingMetric> weeks = new ArrayList<>(period.weeks());
        int sessions = 0;
        int minutes = 0;
        int calories = 0;
        double rpeWeighted = 0;
        int rpeSessions = 0;
        for (LocalDate w = from; !w.isAfter(currentWeek); w = w.plusWeeks(1)) {
            WeeklyTrainingMetric m = byWeek.getOrDefault(w, WeeklyTrainingMetric.empty(w));
            weeks.add(m);
            sessions += m.sessions();
            minutes += m.totalMinutes();
            calories += m.totalCalories();
            if (m.averageRpe() != null && m.sessions() > 0) {
                rpeWeighted += m.averageRpe() * m.sessions();
                rpeSessions += m.sessions();
            }
        }
        Double avgRpe = rpeSessions == 0 ? null : rpeWeighted / rpeSessions;
        return new WeeklyAnalytics(period, from, currentWeek, weeks, sessions, minutes, calories, avgRpe);
    }
}
