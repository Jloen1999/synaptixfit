package com.synaptixfit.domain.model.analytics;

import java.time.DayOfWeek;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;

/**
 * Agregado semanal de entrenamiento. Se calcula aquí con {@link #byWeek(Collection, ZoneId)} a partir de las
 * sesiones completadas (antes lo hacía la vista SQL {@code v_analitica_semanal}).
 *
 * @param averageRpe RPE medio de la semana (1 decimal); null si ninguna sesión tiene RPE
 */
public record WeeklyTrainingMetric(LocalDate weekStart, int sessions, Double averageRpe, int totalMinutes,
                                   int totalCalories) {

    /** Sesión completada tal como se guarda; {@code calories} y {@code rpe} pueden faltar. */
    public record CompletedSession(Instant completedAt, int minutes, Double calories, Integer rpe) {
    }

    public static WeeklyTrainingMetric empty(LocalDate weekStart) {
        return new WeeklyTrainingMetric(weekStart, 0, null, 0, 0);
    }

    /**
     * Agrupa las sesiones por semana (de lunes a domingo en la zona {@code zone}, la del usuario) y
     * devuelve solo las semanas con sesiones, en orden ascendente. El RPE medio ignora las sesiones
     * sin RPE.
     */
    public static List<WeeklyTrainingMetric> byWeek(Collection<CompletedSession> sessions, ZoneId zone) {
        Map<LocalDate, List<CompletedSession>> weeks = new TreeMap<>();
        for (CompletedSession s : sessions) {
            weeks.computeIfAbsent(weekStart(s.completedAt(), zone), k -> new ArrayList<>()).add(s);
        }
        List<WeeklyTrainingMetric> result = new ArrayList<>(weeks.size());
        weeks.forEach((week, list) -> {
            int minutes = list.stream().mapToInt(CompletedSession::minutes).sum();
            double calories = list.stream().mapToDouble(s -> s.calories() == null ? 0 : s.calories()).sum();
            double avgRpe = list.stream().filter(s -> s.rpe() != null && s.rpe() > 0)
                    .mapToInt(CompletedSession::rpe).average().orElse(Double.NaN);
            result.add(new WeeklyTrainingMetric(week, list.size(),
                    Double.isNaN(avgRpe) ? null : Math.round(avgRpe * 10) / 10.0, minutes, (int) Math.round(calories)));
        });
        return result;
    }

    /** Lunes de la semana del instante en la zona dada. */
    public static LocalDate weekStart(Instant instant, ZoneId zone) {
        return LocalDate.ofInstant(instant, zone).with(DayOfWeek.MONDAY);
    }
}
