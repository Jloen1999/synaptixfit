package com.synaptixfit.domain.model.analytics;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.assertj.core.api.Assertions.within;

import com.synaptixfit.domain.exception.analytics.InvalidAnalyticsPeriodException;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import org.junit.jupiter.api.Test;

/** Pearson, tendencias, relleno de semanas e interpretaciones. */
class AnalyticsDomainTest {

    private static final LocalDate W0 = LocalDate.of(2026, 9, 7); // lunes

    @Test
    void pearsonPerfectAndInverseCorrelation() {
        assertThat(Statistics.pearson(List.of(1.0, 2.0, 3.0, 4.0, 5.0), List.of(2.0, 4.0, 6.0, 8.0, 10.0)))
                .isCloseTo(1.0, within(1e-12));
        assertThat(Statistics.pearson(List.of(1.0, 2.0, 3.0, 4.0, 5.0), List.of(10.0, 8.0, 6.0, 4.0, 2.0)))
                .isCloseTo(-1.0, within(1e-12));
    }

    @Test
    void pearsonKnownValue() {
        // medias 2.5; Sxy = 4, Sxx = Syy = 5 → r = 0.8
        assertThat(Statistics.pearson(List.of(1.0, 2.0, 3.0, 4.0), List.of(1.0, 3.0, 2.0, 4.0)))
                .isCloseTo(0.8, within(1e-12));
        // Horas de estudio vs RPE (ejemplo realista): r ≈ -0.9646
        assertThat(Statistics.pearson(List.of(10.0, 15.0, 20.0, 25.0, 30.0), List.of(8.0, 7.5, 7.0, 5.0, 4.5)))
                .isCloseTo(-0.9646, within(1e-4));
    }

    @Test
    void pearsonIsUndefinedWithoutVariance() {
        assertThat(Statistics.pearson(List.of(3.0, 3.0, 3.0), List.of(1.0, 2.0, 3.0))).isNull();
        assertThat(Statistics.pearson(List.of(1.0), List.of(1.0))).isNull();
    }

    @Test
    void correlationAlignsWeeksAndNeedsFourSamples() {
        List<WeeklyStudyLoad> study = new ArrayList<>();
        List<WeeklyTrainingMetric> training = new ArrayList<>();
        double[] hours = {10, 15, 20, 25, 30};
        double[] rpe = {8, 7.5, 7, 5, 4.5};
        for (int i = 0; i < 5; i++) {
            study.add(new WeeklyStudyLoad(W0.plusWeeks(i), hours[i]));
            training.add(new WeeklyTrainingMetric(W0.plusWeeks(i), 2, rpe[i], 90, 500));
        }
        study.add(new WeeklyStudyLoad(W0.plusWeeks(5), 0));          // sin estudio: no cuenta
        training.add(new WeeklyTrainingMetric(W0.plusWeeks(6), 1, 6.0, 30, 100)); // sin carga académica

        LoadCorrelation c = LoadCorrelation.compute(CorrelationMetric.RPE, study, training);
        assertThat(c.sampleSize()).isEqualTo(5);
        assertThat(c.sufficientData()).isTrue();
        assertThat(c.coefficient()).isCloseTo(-0.9646, within(1e-4));
        assertThat(c.strength()).isEqualTo(LoadCorrelation.Strength.VERY_STRONG);
        assertThat(c.direction()).isEqualTo(LoadCorrelation.Direction.NEGATIVE);

        LoadCorrelation few = LoadCorrelation.compute(CorrelationMetric.MINUTES, study.subList(0, 3), training);
        assertThat(few.sufficientData()).isFalse();
        assertThat(few.coefficient()).isNull();
        assertThat(few.points()).hasSize(3);
    }

    @Test
    void weeklyAnalyticsFillsMissingWeeks() {
        LocalDate current = W0.plusWeeks(3);
        WeeklyAnalytics a = WeeklyAnalytics.of(AnalyticsPeriod.WEEKLY, current, List.of(
                new WeeklyTrainingMetric(W0, 2, 6.0, 90, 600),
                new WeeklyTrainingMetric(W0.plusWeeks(2), 1, 9.0, 30, 200)));
        assertThat(a.weeks()).hasSize(4);
        assertThat(a.weeks().get(1).sessions()).isZero();
        assertThat(a.weeks().get(1).averageRpe()).isNull();
        assertThat(a.totalSessions()).isEqualTo(3);
        assertThat(a.averageRpe()).isCloseTo(7.0, within(1e-9));

        RpeTrend trend = RpeTrend.of(a);
        assertThat(trend.points()).hasSize(2);
        assertThat(trend.slopePerWeek()).isCloseTo(1.5, within(1e-9));
        assertThat(trend.direction()).isEqualTo(RpeTrend.Direction.UP);

        TrainingVolume volume = TrainingVolume.of(a);
        assertThat(volume.averageMinutesPerWeek()).isEqualTo(30);
    }

    @Test
    void periodParsing() {
        assertThat(AnalyticsPeriod.parse(null)).isEqualTo(AnalyticsPeriod.MONTHLY);
        assertThat(AnalyticsPeriod.parse("quarterly").weeks()).isEqualTo(26);
        assertThatThrownBy(() -> AnalyticsPeriod.parse("YEARLY"))
                .isInstanceOf(InvalidAnalyticsPeriodException.class)
                .extracting("code").isEqualTo("ANALYTICS_INVALID_PERIOD");
    }

    @Test
    void consistencySkipsTheCurrentWeekWhenItHasNoSessionsYet() {
        LocalDate current = W0.plusWeeks(3);
        List<WeeklyTrainingMetric> weeks = List.of(
                new WeeklyTrainingMetric(W0, 1, 5.0, 30, 0),
                WeeklyTrainingMetric.empty(W0.plusWeeks(1)),
                new WeeklyTrainingMetric(W0.plusWeeks(2), 2, 5.0, 60, 0),
                WeeklyTrainingMetric.empty(current));
        assertThat(InsightGenerator.consecutiveTrainingWeeks(weeks, current)).isEqualTo(1);
    }

    @Test
    void insightsAreStructured() {
        Insight streak = InsightGenerator.streak(12);
        assertThat(streak.variant()).isEqualTo("WEEKS");
        assertThat(streak.severity()).isEqualTo(Insight.Severity.POSITIVE);
        assertThat(streak.params()).containsEntry("days", 12).containsEntry("weeks", 1);
        assertThat(InsightGenerator.streak(0).severity()).isEqualTo(Insight.Severity.INFO);
        assertThat(InsightGenerator.consistency(5).variant()).isEqualTo("ELITE");
        assertThat(InsightGenerator.volume(30, 4).variant()).isEqualTo("LOW");

        LoadCorrelation negative = new LoadCorrelation(CorrelationMetric.RPE, -0.65, 6, true,
                LoadCorrelation.Strength.STRONG, LoadCorrelation.Direction.NEGATIVE, List.of());
        Insight c = InsightGenerator.correlation(negative);
        assertThat(c.variant()).isEqualTo("STRONG_NEGATIVE");
        assertThat(c.severity()).isEqualTo(Insight.Severity.WARNING);
        assertThat(c.params()).containsEntry("percent", 65L).containsEntry("sampleSize", 6);
    }
}
