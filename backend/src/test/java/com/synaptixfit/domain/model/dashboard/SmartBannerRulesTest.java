package com.synaptixfit.domain.model.dashboard;

import static org.assertj.core.api.Assertions.assertThat;

import com.synaptixfit.domain.model.insights.AcwrZone;
import com.synaptixfit.domain.model.user.UsageFocus;
import org.junit.jupiter.api.Test;

/** Prioridad de las reglas del banner inteligente. */
class SmartBannerRulesTest {

    /** Contexto neutro: con check-in, sin señales. */
    private static Builder base() {
        return new Builder();
    }

    @Test
    void physicalOverloadHasTopPriority() {
        SmartBanner b = SmartBannerRules.choose(base().zone(AcwrZone.OVERTRAINING, 2.346).deadlines(2, 1).build());
        assertThat(b.type()).isEqualTo(SmartBanner.Type.PHYSICAL_OVERLOAD);
        assertThat(b.params()).containsEntry("acwr", 2.35).containsEntry("maxStudyMinutes", 45);
    }

    @Test
    void upcomingDeadlinesBeatFatigueAndEnergy() {
        SmartBanner b = SmartBannerRules.choose(base().deadlines(2, 3).fatigue(80).energy(10).build());
        assertThat(b.type()).isEqualTo(SmartBanner.Type.UPCOMING_DEADLINES);
        assertThat(b.params()).containsEntry("count", 2).containsEntry("daysUntilNext", 3);
    }

    @Test
    void fatigueThenAdherenceThenEnergy() {
        assertThat(SmartBannerRules.choose(base().fatigue(60).adherence(10.0).build()).type())
                .isEqualTo(SmartBanner.Type.HIGH_FATIGUE);
        assertThat(SmartBannerRules.choose(base().adherence(35.0).energy(10).build()).type())
                .isEqualTo(SmartBanner.Type.LOW_ADHERENCE);
        assertThat(SmartBannerRules.choose(base().energy(20).build()).type())
                .isEqualTo(SmartBanner.Type.LOW_ENERGY);
    }

    @Test
    void lowEnergyIsIgnoredWithoutCheckIn() {
        SmartBanner b = SmartBannerRules.choose(base().energy(10).noCheckIn().build());
        assertThat(b.type()).isEqualTo(SmartBanner.Type.CHECK_IN_PENDING);
    }

    @Test
    void attentionPeakDayAndStreaks() {
        assertThat(SmartBannerRules.choose(base().attention(0.3).build()).type())
                .isEqualTo(SmartBanner.Type.ATTENTION_DEPLETED);
        assertThat(SmartBannerRules.choose(base().energy(80).stress(3).build()).type())
                .isEqualTo(SmartBanner.Type.PEAK_DAY);
        // Estrés desconocido = 5: no es un día pico.
        assertThat(SmartBannerRules.choose(base().energy(80).build()).type())
                .isEqualTo(SmartBanner.Type.BALANCE);
        assertThat(SmartBannerRules.choose(base().studyStreak(6).trainingStreak(9).build()).type())
                .isEqualTo(SmartBanner.Type.STUDY_STREAK);
        SmartBanner training = SmartBannerRules.choose(base().trainingStreak(9).build());
        assertThat(training.type()).isEqualTo(SmartBanner.Type.TRAINING_STREAK);
        assertThat(training.params()).containsEntry("days", 9);
    }

    @Test
    void comebackAfterInactivity() {
        SmartBanner b = SmartBannerRules.choose(base().inactive(10).noCheckIn().build());
        assertThat(b.type()).isEqualTo(SmartBanner.Type.COMEBACK);
        assertThat(b.params()).containsEntry("daysInactive", 10).containsEntry("loadFactor", 0.8);
        assertThat(SmartBannerRules.choose(base().inactive(45).build()).type()).isEqualTo(SmartBanner.Type.BALANCE);
    }

    @Test
    void onlyAcademicFocusSkipsTrainingSignals() {
        BannerContext overloadedStudent = base().zone(AcwrZone.OVERTRAINING, 2.3).fatigue(80).noCheckIn()
                .deadlines(1, 2).focus(UsageFocus.ACADEMIC).build();
        assertThat(SmartBannerRules.choose(overloadedStudent).type()).isEqualTo(SmartBanner.Type.UPCOMING_DEADLINES);
        assertThat(SmartBannerRules.choose(base().noCheckIn().trainingStreak(9).focus(UsageFocus.ACADEMIC).build())
                .type()).isEqualTo(SmartBanner.Type.BALANCE);
    }

    @Test
    void onlyFitnessFocusSkipsStudySignals() {
        BannerContext athlete = base().deadlines(3, 1).adherence(10.0).attention(0.2).studyStreak(9)
                .focus(UsageFocus.FITNESS).build();
        assertThat(SmartBannerRules.choose(athlete).type()).isEqualTo(SmartBanner.Type.BALANCE);
        assertThat(SmartBannerRules.choose(base().deadlines(3, 1).noCheckIn().focus(UsageFocus.FITNESS).build())
                .type()).isEqualTo(SmartBanner.Type.CHECK_IN_PENDING);
    }

    private static final class Builder {
        private AcwrZone zone = AcwrZone.OPTIMAL;
        private Double acwr = 1.0;
        private int deadlines;
        private Integer daysUntil;
        private Integer fatigue;
        private Double adherence;
        private Double energy = 55.0;
        private boolean checkIn = true;
        private Integer stress;
        private double attention = 1.0;
        private int trainingStreak;
        private int studyStreak;
        private Integer inactive = 1;
        private UsageFocus focus = UsageFocus.BOTH;

        Builder zone(AcwrZone z, double a) { zone = z; acwr = a; return this; }
        Builder deadlines(int count, int days) { deadlines = count; daysUntil = days; return this; }
        Builder fatigue(int f) { fatigue = f; return this; }
        Builder adherence(Double a) { adherence = a; return this; }
        Builder energy(double e) { energy = e; return this; }
        Builder noCheckIn() { checkIn = false; return this; }
        Builder stress(int s) { stress = s; return this; }
        Builder attention(double a) { attention = a; return this; }
        Builder trainingStreak(int d) { trainingStreak = d; return this; }
        Builder studyStreak(int d) { studyStreak = d; return this; }
        Builder inactive(int d) { inactive = d; return this; }
        Builder focus(UsageFocus f) { focus = f; return this; }

        BannerContext build() {
            return new BannerContext(zone, acwr, zone.isRisky() ? 45 : 90, deadlines, daysUntil, fatigue, adherence,
                    energy, checkIn, stress, attention, 0.5, trainingStreak, studyStreak, inactive, focus);
        }
    }
}
