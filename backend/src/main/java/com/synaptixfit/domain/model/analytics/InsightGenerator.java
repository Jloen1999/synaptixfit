package com.synaptixfit.domain.model.analytics;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Reglas de interpretación de la analítica (antes {@code insight_generator.dart}, que devolvía
 * frases en español). Ahora devuelve {@link Insight}s con tipo, variante y parámetros.
 */
public final class InsightGenerator {

    private InsightGenerator() {
    }

    public static List<Insight> generate(int trainingStreakDays, WeeklyAnalytics analytics, LoadCorrelation correlation) {
        List<Insight> insights = new ArrayList<>();
        insights.add(streak(trainingStreakDays));
        insights.add(consistency(consecutiveTrainingWeeks(analytics.weeks(), analytics.toWeek())));
        insights.add(volume(analytics.totalMinutes(), analytics.weeks().size()));
        if (correlation != null && correlation.sufficientData()) {
            insights.add(correlation(correlation));
        }
        return insights;
    }

    /** Racha diaria: NONE (0), FIRST_DAY (1), BUILDING (2-6), WEEKS (7-29), HABIT (30-89), UNSTOPPABLE (90+). */
    public static Insight streak(int days) {
        int d = Math.max(0, days);
        String variant;
        if (d == 0) {
            variant = "NONE";
        } else if (d == 1) {
            variant = "FIRST_DAY";
        } else if (d < 7) {
            variant = "BUILDING";
        } else if (d < 30) {
            variant = "WEEKS";
        } else if (d < 90) {
            variant = "HABIT";
        } else {
            variant = "UNSTOPPABLE";
        }
        return new Insight(Insight.Type.STREAK, d == 0 ? Insight.Severity.INFO : Insight.Severity.POSITIVE, variant,
                params("days", d, "weeks", d / 7));
    }

    /** Semanas consecutivas con entrenamiento: NONE (0), FIRST_WEEK (1), BUILDING (2-3), ELITE (4+). */
    public static Insight consistency(int weeks) {
        int w = Math.max(0, weeks);
        String variant = w == 0 ? "NONE" : w == 1 ? "FIRST_WEEK" : w < 4 ? "BUILDING" : "ELITE";
        return new Insight(Insight.Type.CONSISTENCY, w == 0 ? Insight.Severity.INFO : Insight.Severity.POSITIVE,
                variant, params("weeks", w));
    }

    /** Volumen del periodo: LOW si no llega a 1 hora, ACCUMULATED en otro caso. */
    public static Insight volume(int totalMinutes, int weeks) {
        int w = Math.max(1, weeks);
        double hours = totalMinutes / 60.0;
        boolean low = hours < 1;
        return new Insight(Insight.Type.VOLUME, low ? Insight.Severity.WARNING : Insight.Severity.POSITIVE,
                low ? "LOW" : "ACCUMULATED",
                params("totalMinutes", totalMinutes, "totalHours", round1(hours), "weeks", w,
                        "averageHoursPerWeek", round1(hours / w)));
    }

    /**
     * Correlación estudio-entrenamiento: variante {@code NONE} o {@code <FUERZA>_<DIRECCIÓN>}
     * (p. ej. {@code STRONG_NEGATIVE}). Una relación negativa moderada o mayor es un aviso.
     */
    public static Insight correlation(LoadCorrelation c) {
        double r = c.coefficient();
        LoadCorrelation.Strength strength = c.strength();
        String variant = strength == LoadCorrelation.Strength.NONE ? "NONE" : strength.name() + "_" + c.direction().name();
        Insight.Severity severity;
        if (strength == LoadCorrelation.Strength.NONE) {
            severity = Insight.Severity.INFO;
        } else if (r > 0) {
            severity = Insight.Severity.POSITIVE;
        } else {
            severity = Math.abs(r) >= 0.4 ? Insight.Severity.WARNING : Insight.Severity.INFO;
        }
        return new Insight(Insight.Type.CORRELATION, severity, variant,
                params("coefficient", round2(r), "percent", Math.round(Math.abs(r) * 100), "sampleSize", c.sampleSize()));
    }

    /**
     * Semanas consecutivas con al menos una sesión, contando hacia atrás desde la semana actual.
     * Si la semana actual (aún en curso) no tiene sesiones, se empieza a contar por la anterior.
     */
    public static int consecutiveTrainingWeeks(List<WeeklyTrainingMetric> weeks, LocalDate currentWeek) {
        Map<LocalDate, Integer> sessions = new HashMap<>();
        weeks.forEach(w -> sessions.put(w.weekStart(), w.sessions()));
        LocalDate cursor = currentWeek;
        if (sessions.getOrDefault(cursor, 0) == 0) {
            cursor = cursor.minusWeeks(1);
        }
        int count = 0;
        while (sessions.getOrDefault(cursor, 0) > 0) {
            count++;
            cursor = cursor.minusWeeks(1);
        }
        return count;
    }

    private static Map<String, Number> params(Object... kv) {
        Map<String, Number> map = new LinkedHashMap<>();
        for (int i = 0; i < kv.length; i += 2) {
            map.put((String) kv[i], (Number) kv[i + 1]);
        }
        return map;
    }

    private static double round1(double v) {
        return Math.round(v * 10) / 10.0;
    }

    private static double round2(double v) {
        return Math.round(v * 100) / 100.0;
    }
}
