package com.synaptixfit.domain.model.analytics;

import java.time.LocalDate;
import java.util.List;

/** Volumen semanal (minutos, calorías y sesiones por semana) y medias por semana del periodo. */
public record TrainingVolume(AnalyticsPeriod period, List<Point> points, double averageMinutesPerWeek,
                             double averageCaloriesPerWeek, double averageSessionsPerWeek) {

    public TrainingVolume {
        points = List.copyOf(points);
    }

    public record Point(LocalDate weekStart, int sessions, int minutes, int calories) {
    }

    public static TrainingVolume of(WeeklyAnalytics analytics) {
        List<Point> points = analytics.weeks().stream()
                .map(w -> new Point(w.weekStart(), w.sessions(), w.totalMinutes(), w.totalCalories()))
                .toList();
        int weeks = Math.max(1, points.size());
        return new TrainingVolume(analytics.period(), points, (double) analytics.totalMinutes() / weeks,
                (double) analytics.totalCalories() / weeks, (double) analytics.totalSessions() / weeks);
    }
}
