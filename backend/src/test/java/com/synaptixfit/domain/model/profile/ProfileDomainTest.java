package com.synaptixfit.domain.model.profile;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.domain.exception.FieldValidationException;
import com.synaptixfit.domain.exception.profile.InvalidClassDatesException;
import com.synaptixfit.domain.model.user.UsageFocus;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class ProfileDomainTest {

    private final Instant now = Instant.parse("2026-10-01T10:00:00Z");

    @Test
    void bmiIsComputedAndRoundedToOneDecimal() {
        assertThat(new BodyMeasurement(70, 175).bmi()).isEqualTo(22.9);
        assertThat(new BodyMeasurement(30, 230).bmi()).isEqualTo(5.7);
        assertThatThrownBy(() -> new BodyMeasurement(29.9, 175)).isInstanceOf(FieldValidationException.class)
                .extracting("field").isEqualTo("weightKg");
        assertThatThrownBy(() -> new BodyMeasurement(70, 231)).isInstanceOf(FieldValidationException.class)
                .extracting("field").isEqualTo("heightCm");
    }

    @Test
    void trainingGoalResolvesCanonicalAndLegacyTexts() {
        assertThat(TrainingGoal.fromLabel("fuerza maxima")).contains(TrainingGoal.MAX_STRENGTH);
        assertThat(TrainingGoal.fromLabel("Acondicionamiento Metabólico")).contains(TrainingGoal.METABOLIC_CONDITIONING);
        assertThat(TrainingGoal.fromLabel("perder_peso")).contains(TrainingGoal.METABOLIC_CONDITIONING);
        assertThat(TrainingGoal.fromLabel("POWER")).contains(TrainingGoal.POWER);
        assertThat(TrainingGoal.fromLabel("algo raro")).isEmpty();
    }

    @Test
    void wellnessProfileDerivesDaysPerWeekAndCleansLists() {
        WellnessProfile p = WellnessProfile.builder().id(UUID.randomUUID()).userId(UUID.randomUUID()).age(20)
                .sex(Sex.NON_BINARY).city("  ").measurement(new BodyMeasurement(65, 170))
                .activityLevel(ActivityLevel.SEDENTARY).primaryGoal(TrainingGoal.MOBILITY)
                .goals(List.of(" Estar sano ", "", "Estar sano")).equipment(List.of("Banda_Elastica"))
                .availableDays(List.of(7, 1, 7)).minutesPerSession(10).createdAt(now).build();

        assertThat(p.city()).isNull();
        assertThat(p.goals()).containsExactly("Estar sano");
        assertThat(p.equipment()).containsExactly("banda_elastica");
        assertThat(p.availableDays()).containsExactly(1, 7);
        assertThat(p.daysPerWeek()).isEqualTo(2);
        assertThat(p.updatedAt()).isEqualTo(now);
        assertThat(p.changePrimaryGoal(TrainingGoal.MOBILITY)).isFalse();
        assertThat(p.changePrimaryGoal(TrainingGoal.STABILITY)).isTrue();
        assertThat(p.goals()).containsExactly("Estar sano");
    }

    @Test
    void wellnessProfileRejectsEmptyDaysAndTooManyMinutes() {
        WellnessProfile.Builder builder = WellnessProfile.builder().id(UUID.randomUUID()).userId(UUID.randomUUID())
                .age(20).sex(Sex.MALE).measurement(new BodyMeasurement(65, 170)).activityLevel(ActivityLevel.HIGH)
                .primaryGoal(TrainingGoal.POWER).minutesPerSession(60).createdAt(now);
        assertThatThrownBy(() -> builder.availableDays(List.of()).build())
                .isInstanceOf(FieldValidationException.class).extracting("fieldCode").isEqualTo("REQUIRED");
        assertThatThrownBy(() -> builder.availableDays(List.of(1)).minutesPerSession(181).build())
                .isInstanceOf(FieldValidationException.class).extracting("field").isEqualTo("minutesPerSession");
    }

    @Test
    void academicProfileValidatesRangesAndDates() {
        AcademicProfile p = AcademicProfile.createDefault(UUID.randomUUID(), now);
        assertThatThrownBy(() -> p.changeSemester(21)).isInstanceOf(FieldValidationException.class);
        assertThatThrownBy(() -> p.changeTargetGpa(5.1)).isInstanceOf(FieldValidationException.class);
        assertThatThrownBy(() -> p.changeSemesterCredits(61)).isInstanceOf(FieldValidationException.class);
        assertThatThrownBy(() -> p.changeClassDates(LocalDate.parse("2027-01-01"), LocalDate.parse("2026-12-31")))
                .isInstanceOf(InvalidClassDatesException.class);
        p.changeClassDates(LocalDate.parse("2026-09-15"), LocalDate.parse("2026-09-15"));
        assertThat(p.hasSemesterDates()).isTrue();
        p.changeClassDates(LocalDate.parse("2026-09-15"), null);
        assertThat(p.hasSemesterDates()).isFalse();
    }

    @Test
    void closingGoalPeriodNeverEndsBeforeItStarts() {
        GoalHistoryEntry entry = GoalHistoryEntry.open(UUID.randomUUID(), TrainingGoal.POWER, null,
                LocalDate.parse("2026-10-10"), now);
        entry.close(LocalDate.parse("2026-10-01"));
        assertThat(entry.endDate()).isEqualTo(LocalDate.parse("2026-10-10"));
        assertThat(entry.isOpen()).isFalse();
    }

    @Test
    void onboardingStatusOrdersPendingSteps() {
        OnboardingStatus status = new OnboardingStatus(true, UsageFocus.BOTH, false, true, false, false);
        assertThat(status.pendingSteps()).containsExactly(OnboardingStep.WELLNESS_PROFILE, OnboardingStep.SUBJECTS);
        assertThat(status.nextStep()).isEqualTo(OnboardingStep.WELLNESS_PROFILE);
        assertThat(status.completed()).isFalse();
        assertThat(new OnboardingStatus(true, UsageFocus.BOTH, false, true, false, true).completed()).isTrue();
    }

    @Test
    void onboardingStepsDependOnTheUsageFocus() {
        assertThat(new OnboardingStatus(true, null, false, false, false, false).pendingSteps()).containsExactly(
                OnboardingStep.FOCUS, OnboardingStep.WELLNESS_PROFILE, OnboardingStep.ACADEMIC_PROFILE,
                OnboardingStep.SUBJECTS);
        assertThat(new OnboardingStatus(true, UsageFocus.FITNESS, false, false, false, false).pendingSteps())
                .containsExactly(OnboardingStep.WELLNESS_PROFILE);
        OnboardingStatus academic = new OnboardingStatus(true, UsageFocus.ACADEMIC, false, true, true, false);
        assertThat(academic.pendingSteps()).isEmpty();
        assertThat(academic.completed()).isTrue();
    }

    @Test
    void ruleBasedSuggestionsDependOnActivityAndAge() {
        GoalSuggestions sedentary = GoalSuggestionRules.suggest(new GoalSuggestionContext(null, null, null, null));
        assertThat(sedentary.source()).isEqualTo(GoalSuggestionSource.RULES);
        assertThat(sedentary.suggestions()).extracting(GoalSuggestion::goal).containsExactly(
                TrainingGoal.METABOLIC_CONDITIONING, TrainingGoal.MOBILITY, TrainingGoal.STABILITY);

        GoalSuggestions young = GoalSuggestionRules.suggest(
                new GoalSuggestionContext(22, Sex.MALE, ActivityLevel.HIGH, null));
        assertThat(young.suggestions()).extracting(GoalSuggestion::goal).containsExactly(
                TrainingGoal.MAX_STRENGTH, TrainingGoal.HYPERTROPHY, TrainingGoal.POWER);

        GoalSuggestions senior = GoalSuggestionRules.suggest(
                new GoalSuggestionContext(60, Sex.FEMALE, ActivityLevel.HIGH, null));
        assertThat(senior.suggestions()).extracting(GoalSuggestion::goal).containsExactly(
                TrainingGoal.MOBILITY, TrainingGoal.STABILITY, TrainingGoal.MAX_STRENGTH);
    }
}
