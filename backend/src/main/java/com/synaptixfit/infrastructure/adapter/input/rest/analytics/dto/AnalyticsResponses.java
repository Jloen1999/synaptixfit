package com.synaptixfit.infrastructure.adapter.input.rest.analytics.dto;

import com.synaptixfit.domain.model.analytics.AnalyticsPeriod;
import com.synaptixfit.domain.model.analytics.CorrelationMetric;
import com.synaptixfit.domain.model.analytics.Insight;
import com.synaptixfit.domain.model.analytics.LoadCorrelation;
import com.synaptixfit.domain.model.analytics.RpeTrend;
import com.synaptixfit.domain.model.analytics.StudyWeekSummary;
import com.synaptixfit.domain.model.analytics.TrainingVolume;
import com.synaptixfit.domain.model.analytics.WeeklyAnalytics;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;

/** DTOs de respuesta de la analítica. */
public final class AnalyticsResponses {

    private AnalyticsResponses() {
    }

    private static Double round(Double v, int decimals) {
        if (v == null) {
            return null;
        }
        double factor = Math.pow(10, decimals);
        return Math.round(v * factor) / factor;
    }

    public record WeekMetricResponse(LocalDate weekStart, int sessions, Double averageRpe, int totalMinutes,
                                     int totalCalories) {
    }

    /** Serie semanal completa (semanas sin sesiones con ceros y RPE null) y totales del periodo. */
    public record WeeklyAnalyticsResponse(AnalyticsPeriod period, LocalDate fromWeek, LocalDate toWeek,
                                          List<WeekMetricResponse> weeks, int totalSessions, int totalMinutes,
                                          int totalCalories, Double averageRpe) {

        public static WeeklyAnalyticsResponse from(WeeklyAnalytics a) {
            return new WeeklyAnalyticsResponse(a.period(), a.fromWeek(), a.toWeek(),
                    a.weeks().stream().map(w -> new WeekMetricResponse(w.weekStart(), w.sessions(),
                            round(w.averageRpe(), 1), w.totalMinutes(), w.totalCalories())).toList(),
                    a.totalSessions(), a.totalMinutes(), a.totalCalories(), round(a.averageRpe(), 1));
        }
    }

    public record RpePointResponse(LocalDate weekStart, double averageRpe) {
    }

    /** Tendencia del RPE: puntos y pendiente (RPE/semana) con su dirección. */
    public record RpeTrendResponse(AnalyticsPeriod period, List<RpePointResponse> points, Double slopePerWeek,
                                   RpeTrend.Direction direction) {

        public static RpeTrendResponse from(RpeTrend t) {
            return new RpeTrendResponse(t.period(),
                    t.points().stream().map(p -> new RpePointResponse(p.weekStart(), round(p.averageRpe(), 1))).toList(),
                    round(t.slopePerWeek(), 3), t.direction());
        }
    }

    public record VolumePointResponse(LocalDate weekStart, int sessions, int minutes, int calories) {
    }

    /** Volumen semanal y medias por semana. */
    public record TrainingVolumeResponse(AnalyticsPeriod period, List<VolumePointResponse> points,
                                         double averageMinutesPerWeek, double averageCaloriesPerWeek,
                                         double averageSessionsPerWeek) {

        public static TrainingVolumeResponse from(TrainingVolume v) {
            return new TrainingVolumeResponse(v.period(),
                    v.points().stream().map(p -> new VolumePointResponse(p.weekStart(), p.sessions(), p.minutes(),
                            p.calories())).toList(),
                    round(v.averageMinutesPerWeek(), 1), round(v.averageCaloriesPerWeek(), 1),
                    round(v.averageSessionsPerWeek(), 2));
        }
    }

    public record CorrelationPointResponse(LocalDate weekStart, double studyHours, double trainingValue) {
    }

    /** Correlación de Pearson; {@code coefficient}, {@code strength} y {@code direction} son null sin datos suficientes. */
    public record CorrelationResponse(CorrelationMetric metric, Double coefficient, int sampleSize,
                                      int minimumSampleSize, boolean sufficientData, LoadCorrelation.Strength strength,
                                      LoadCorrelation.Direction direction, List<CorrelationPointResponse> points) {

        public static CorrelationResponse from(LoadCorrelation c) {
            return new CorrelationResponse(c.metric(), round(c.coefficient(), 3), c.sampleSize(),
                    LoadCorrelation.MIN_SAMPLES, c.sufficientData(), c.strength(), c.direction(),
                    c.points().stream().map(p -> new CorrelationPointResponse(p.weekStart(), p.studyHours(),
                            round(p.trainingValue(), 1))).toList());
        }
    }

    /** Interpretación estructurada: el cliente redacta el texto con type + variant + params. */
    public record InsightResponse(Insight.Type type, Insight.Severity severity, String variant,
                                  Map<String, Number> params) {

        public static InsightResponse from(Insight i) {
            return new InsightResponse(i.type(), i.severity(), i.variant(), i.params());
        }
    }

    /** «Tu estudio» de la semana; {@code planAdherence} y {@code averageTestScore} en %, nulos sin datos. */
    public record StudyWeekResponse(LocalDate weekStart, int focusMinutes, int focusSessions, int studyBlocksPlanned,
                                    int studyBlocksCompleted, Integer planAdherence, int reviewsCompleted,
                                    int testsCompleted, Integer averageTestScore, int reviewsDue, int studyHours,
                                    int weeklyGoalHours, boolean empty) {

        public static StudyWeekResponse from(StudyWeekSummary s) {
            return new StudyWeekResponse(s.weekStart(), s.focusMinutes(), s.focusSessions(), s.studyBlocksPlanned(),
                    s.studyBlocksCompleted(), s.planAdherence(), s.reviewsCompleted(), s.testsCompleted(),
                    s.averageTestScore(), s.reviewsDue(), s.studyHours(), s.weeklyGoalHours(), s.isEmpty());
        }
    }
}
