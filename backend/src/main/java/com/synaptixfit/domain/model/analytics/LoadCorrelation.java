package com.synaptixfit.domain.model.analytics;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Correlación de Pearson entre las horas de estudio semanales y una métrica de entrenamiento.
 * Solo cuentan las semanas con estudio registrado (&gt; 0 h) y con dato de entrenamiento; hacen
 * falta al menos {@value #MIN_SAMPLES} semanas.
 */
public record LoadCorrelation(CorrelationMetric metric, Double coefficient, int sampleSize, boolean sufficientData,
                              Strength strength, Direction direction, List<Point> points) {

    public static final int MIN_SAMPLES = 4;

    public LoadCorrelation {
        points = List.copyOf(points);
    }

    /** Magnitud por |r|: &lt;0.2 nula, &lt;0.4 débil, &lt;0.6 moderada, &lt;0.8 fuerte, resto muy fuerte. */
    public enum Strength {
        NONE, WEAK, MODERATE, STRONG, VERY_STRONG;

        public static Strength of(double r) {
            double abs = Math.abs(r);
            if (abs < 0.2) {
                return NONE;
            }
            if (abs < 0.4) {
                return WEAK;
            }
            if (abs < 0.6) {
                return MODERATE;
            }
            return abs < 0.8 ? STRONG : VERY_STRONG;
        }
    }

    public enum Direction { POSITIVE, NEGATIVE }

    /** @param trainingValue RPE medio o minutos, según la métrica */
    public record Point(LocalDate weekStart, double studyHours, double trainingValue) {
    }

    public static LoadCorrelation compute(CorrelationMetric metric, List<WeeklyStudyLoad> study,
                                          List<WeeklyTrainingMetric> training) {
        Map<LocalDate, WeeklyTrainingMetric> byWeek = new HashMap<>();
        training.forEach(t -> byWeek.put(t.weekStart(), t));
        List<Point> points = new ArrayList<>();
        for (WeeklyStudyLoad s : study) {
            WeeklyTrainingMetric t = byWeek.get(s.weekStart());
            if (s.studyHours() <= 0 || t == null || t.sessions() <= 0) {
                continue;
            }
            Double value = metric == CorrelationMetric.RPE ? t.averageRpe() : Double.valueOf(t.totalMinutes());
            if (value != null) {
                points.add(new Point(s.weekStart(), s.studyHours(), value));
            }
        }
        points.sort((a, b) -> a.weekStart().compareTo(b.weekStart()));
        Double r = points.size() < MIN_SAMPLES ? null : Statistics.pearson(
                points.stream().map(Point::studyHours).toList(),
                points.stream().map(Point::trainingValue).toList());
        boolean sufficient = r != null;
        return new LoadCorrelation(metric, r, points.size(), sufficient,
                sufficient ? Strength.of(r) : null,
                sufficient ? (r >= 0 ? Direction.POSITIVE : Direction.NEGATIVE) : null,
                points);
    }
}
