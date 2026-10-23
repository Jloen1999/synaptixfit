package com.synaptixfit.domain.model.analytics;

import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.List;

/**
 * Tendencia del RPE medio semanal: puntos de las semanas con sesiones y pendiente de la recta de
 * regresión (puntos de RPE por semana). |pendiente| &lt; 0.1 se considera estable.
 */
public record RpeTrend(AnalyticsPeriod period, List<Point> points, Double slopePerWeek, Direction direction) {

    static final double STABLE_THRESHOLD = 0.1;

    public RpeTrend {
        points = List.copyOf(points);
    }

    public enum Direction { UP, DOWN, STABLE, INSUFFICIENT_DATA }

    public record Point(LocalDate weekStart, double averageRpe) {
    }

    public static RpeTrend of(WeeklyAnalytics analytics) {
        List<Point> points = analytics.weeks().stream()
                .filter(w -> w.sessions() > 0 && w.averageRpe() != null)
                .map(w -> new Point(w.weekStart(), w.averageRpe()))
                .toList();
        List<Double> x = points.stream()
                .map(p -> (double) ChronoUnit.WEEKS.between(analytics.fromWeek(), p.weekStart()))
                .toList();
        List<Double> y = points.stream().map(Point::averageRpe).toList();
        Double slope = Statistics.slope(x, y);
        Direction direction;
        if (slope == null) {
            direction = Direction.INSUFFICIENT_DATA;
        } else if (Math.abs(slope) < STABLE_THRESHOLD) {
            direction = Direction.STABLE;
        } else {
            direction = slope > 0 ? Direction.UP : Direction.DOWN;
        }
        return new RpeTrend(analytics.period(), points, slope, direction);
    }
}
