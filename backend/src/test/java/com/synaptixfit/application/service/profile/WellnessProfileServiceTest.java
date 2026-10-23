package com.synaptixfit.application.service.profile;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.application.port.input.profile.SaveWellnessProfileUseCase;
import com.synaptixfit.application.port.input.profile.SuggestGoalsUseCase;
import com.synaptixfit.application.port.input.profile.UpdateWellnessProfileUseCase;
import com.synaptixfit.domain.exception.AiQuotaExceededException;
import com.synaptixfit.domain.exception.AiUnavailableException;
import com.synaptixfit.domain.exception.FieldValidationException;
import com.synaptixfit.domain.exception.profile.WellnessProfileNotFoundException;
import com.synaptixfit.domain.model.profile.ActivityLevel;
import com.synaptixfit.domain.model.profile.GoalHistoryEntry;
import com.synaptixfit.domain.model.profile.GoalSuggestion;
import com.synaptixfit.domain.model.profile.GoalSuggestionContext;
import com.synaptixfit.domain.model.profile.GoalSuggestionSource;
import com.synaptixfit.domain.model.profile.GoalSuggestions;
import com.synaptixfit.domain.model.profile.Sex;
import com.synaptixfit.domain.model.profile.TrainingGoal;
import com.synaptixfit.domain.model.profile.WellnessProfile;
import com.synaptixfit.domain.port.output.profile.GoalSuggestionPort;
import com.synaptixfit.support.ProfileTestDoubles;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class WellnessProfileServiceTest {

    private final UUID userId = UUID.randomUUID();
    private final ProfileTestDoubles.Wellness profiles = new ProfileTestDoubles.Wellness();
    private final ProfileTestDoubles.Weights weights = new ProfileTestDoubles.Weights();
    private final ProfileTestDoubles.Goals goals = new ProfileTestDoubles.Goals();
    private MutableClock clock;
    private GoalSuggestionPort ai;
    private GoalSuggestionContext lastContext;
    private WellnessProfileService service;

    @BeforeEach
    void setUp() {
        clock = new MutableClock(Instant.parse("2026-10-01T10:00:00Z"));
        ai = ctx -> {
            lastContext = ctx;
            throw new AiUnavailableException("no key");
        };
        service = new WellnessProfileService(profiles, weights, goals, ctx -> ai.suggest(ctx), clock);
    }

    private SaveWellnessProfileUseCase.Command fullCommand(double weight, TrainingGoal goal) {
        return new SaveWellnessProfileUseCase.Command(userId, 22, Sex.FEMALE, "Granada", weight, 165,
                ActivityLevel.MODERATE, goal, List.of(), List.of("Mancuerna", "mancuerna", "barra"), List.of(5, 1, 3, 3),
                45);
    }

    private UpdateWellnessProfileUseCase.Command patch(Double weight, TrainingGoal goal) {
        return new UpdateWellnessProfileUseCase.Command(userId, null, null, null, weight, null, null, goal, null, null,
                null, null);
    }

    @Test
    void creatingProfileComputesBmiNormalizesDataAndStartsHistories() {
        WellnessProfile p = service.saveWellnessProfile(fullCommand(60, TrainingGoal.HYPERTROPHY));

        assertThat(p.bmi()).isEqualTo(22.0);
        assertThat(p.availableDays()).containsExactly(1, 3, 5);
        assertThat(p.daysPerWeek()).isEqualTo(3);
        assertThat(p.equipment()).containsExactly("mancuerna", "barra");
        assertThat(p.goals()).containsExactly("Hipertrofia Muscular");
        assertThat(p.onboardingCompleted()).isFalse();
        assertThat(weights.records).hasSize(1);
        assertThat(weights.records.get(0).bmi()).isEqualTo(22.0);
        assertThat(goals.byId.values()).singleElement().satisfies(e -> {
            assertThat(e.goal()).isEqualTo(TrainingGoal.HYPERTROPHY);
            assertThat(e.previousGoal()).isNull();
            assertThat(e.isOpen()).isTrue();
        });
    }

    @Test
    void replacingWithSameMeasurementAndGoalDoesNotTouchHistories() {
        service.saveWellnessProfile(fullCommand(60, TrainingGoal.HYPERTROPHY));
        service.saveWellnessProfile(fullCommand(60, TrainingGoal.HYPERTROPHY));

        assertThat(weights.records).hasSize(1);
        assertThat(goals.byId).hasSize(1);
    }

    @Test
    void changingWeightAppendsToWeightHistory() {
        service.saveWellnessProfile(fullCommand(60, TrainingGoal.HYPERTROPHY));
        clock.set(Instant.parse("2026-10-05T10:00:00Z"));

        WellnessProfile p = service.updateWellnessProfile(patch(63.5, null));

        assertThat(p.weightKg()).isEqualTo(63.5);
        assertThat(p.heightCm()).isEqualTo(165);
        assertThat(p.bmi()).isEqualTo(23.3);
        assertThat(weights.records).hasSize(2);
        assertThat(service.getWeightHistory(userId, LocalDate.parse("2026-10-02"), null)).hasSize(1);
        assertThat(service.getWeightHistory(userId, null, LocalDate.parse("2026-10-01"))).hasSize(1);
    }

    @Test
    void changingGoalClosesOpenPeriodAndOpensNewOne() {
        service.saveWellnessProfile(fullCommand(60, TrainingGoal.HYPERTROPHY));
        clock.set(Instant.parse("2026-11-01T09:00:00Z"));

        WellnessProfile p = service.updateWellnessProfile(patch(null, TrainingGoal.MOBILITY));

        assertThat(p.primaryGoal()).isEqualTo(TrainingGoal.MOBILITY);
        assertThat(p.goals()).containsExactly("Movilidad y Flexibilidad");
        List<GoalHistoryEntry> history = service.getGoalHistory(userId);
        assertThat(history).hasSize(2);
        GoalHistoryEntry current = history.get(0);
        GoalHistoryEntry previous = history.get(1);
        assertThat(current.goal()).isEqualTo(TrainingGoal.MOBILITY);
        assertThat(current.previousGoal()).isEqualTo(TrainingGoal.HYPERTROPHY);
        assertThat(current.isOpen()).isTrue();
        assertThat(previous.endDate()).isEqualTo(LocalDate.parse("2026-11-01"));
        assertThat(weights.records).hasSize(1);
    }

    @Test
    void updatingMissingProfileIsNotFound() {
        assertThatThrownBy(() -> service.updateWellnessProfile(patch(70.0, null)))
                .isInstanceOf(WellnessProfileNotFoundException.class)
                .extracting("code").isEqualTo("PROFILE_WELLNESS_NOT_FOUND");
        assertThatThrownBy(() -> service.getWellnessProfile(userId))
                .isInstanceOf(WellnessProfileNotFoundException.class);
    }

    @Test
    void invalidValuesAreRejectedByTheDomain() {
        assertThatThrownBy(() -> service.saveWellnessProfile(new SaveWellnessProfileUseCase.Command(userId, 14,
                Sex.MALE, null, 70, 175, ActivityLevel.HIGH, TrainingGoal.POWER, null, null, List.of(1), 45)))
                .isInstanceOf(FieldValidationException.class)
                .extracting("field").isEqualTo("age");
        assertThatThrownBy(() -> service.saveWellnessProfile(new SaveWellnessProfileUseCase.Command(userId, 20,
                Sex.MALE, null, 70, 175, ActivityLevel.HIGH, TrainingGoal.POWER, null, null, List.of(8), 45)))
                .isInstanceOf(FieldValidationException.class)
                .extracting("field").isEqualTo("availableDays");
        assertThat(profiles.byUser).isEmpty();
    }

    @Test
    void weightHistoryRejectsInvertedRange() {
        assertThatThrownBy(() -> service.getWeightHistory(userId, LocalDate.parse("2026-10-05"),
                LocalDate.parse("2026-10-01")))
                .isInstanceOf(FieldValidationException.class);
    }

    @Test
    void suggestionsFallBackToRulesWhenAiFailsUsingStoredProfile() {
        service.saveWellnessProfile(fullCommand(60, TrainingGoal.HYPERTROPHY));

        GoalSuggestions result = service.suggestGoals(new SuggestGoalsUseCase.Command(userId, null, null, null, null));

        assertThat(result.source()).isEqualTo(GoalSuggestionSource.RULES);
        assertThat(result.suggestions()).hasSize(3);
        assertThat(result.suggestions().get(0).goal()).isEqualTo(TrainingGoal.HYPERTROPHY);
        assertThat(lastContext.age()).isEqualTo(22);
        assertThat(lastContext.activityLevel()).isEqualTo(ActivityLevel.MODERATE);
    }

    @Test
    void suggestionsAlsoFallBackWhenQuotaIsExceeded() {
        ai = ctx -> {
            throw new AiQuotaExceededException();
        };
        GoalSuggestions result = service.suggestGoals(
                new SuggestGoalsUseCase.Command(userId, 30, Sex.MALE, ActivityLevel.HIGH, null));
        assertThat(result.source()).isEqualTo(GoalSuggestionSource.RULES);
        assertThat(result.suggestions().get(0).goal()).isEqualTo(TrainingGoal.MAX_STRENGTH);
    }

    @Test
    void suggestionsUseAiWhenAvailableAndRequestOverridesProfile() {
        ai = ctx -> {
            lastContext = ctx;
            return List.of(new GoalSuggestion(TrainingGoal.POWER, "a"), new GoalSuggestion(TrainingGoal.HYPERTROPHY, "b"),
                    new GoalSuggestion(TrainingGoal.MOBILITY, "c"), new GoalSuggestion(TrainingGoal.STABILITY, "d"));
        };
        service.saveWellnessProfile(fullCommand(60, TrainingGoal.HYPERTROPHY));

        GoalSuggestions result = service.suggestGoals(
                new SuggestGoalsUseCase.Command(userId, 40, null, ActivityLevel.LIGHT, " Madrid "));

        assertThat(result.source()).isEqualTo(GoalSuggestionSource.AI);
        assertThat(result.suggestions()).hasSize(3);
        assertThat(lastContext.age()).isEqualTo(40);
        assertThat(lastContext.sex()).isEqualTo(Sex.FEMALE);
        assertThat(lastContext.activityLevel()).isEqualTo(ActivityLevel.LIGHT);
        assertThat(lastContext.city()).isEqualTo("Madrid");
    }

    /** Reloj ajustable para simular el paso de los días. */
    static final class MutableClock extends Clock {
        private Instant now;

        MutableClock(Instant now) {
            this.now = now;
        }

        void set(Instant value) {
            this.now = value;
        }

        @Override
        public ZoneOffset getZone() {
            return ZoneOffset.UTC;
        }

        @Override
        public Clock withZone(java.time.ZoneId zone) {
            return this;
        }

        @Override
        public Instant instant() {
            return now;
        }
    }

    @Test
    void shortOnboardingFillsDefaultsAndReplacingKeepsWhatWasThere() {
        WellnessProfile created = service.saveWellnessProfile(new SaveWellnessProfileUseCase.Command(userId, 20,
                Sex.MALE, null, 70, 175, null, TrainingGoal.HYPERTROPHY, null, null, null, null));

        assertThat(created.activityLevel()).isEqualTo(WellnessProfile.DEFAULT_ACTIVITY_LEVEL);
        assertThat(created.availableDays()).isEqualTo(WellnessProfile.DEFAULT_AVAILABLE_DAYS);
        assertThat(created.minutesPerSession()).isEqualTo(WellnessProfile.DEFAULT_MINUTES);

        service.saveWellnessProfile(fullCommand(70, TrainingGoal.HYPERTROPHY));
        WellnessProfile replaced = service.saveWellnessProfile(new SaveWellnessProfileUseCase.Command(userId, 21,
                Sex.MALE, null, 71, 175, null, TrainingGoal.HYPERTROPHY, null, null, null, null));

        assertThat(replaced.age()).isEqualTo(21);
        assertThat(replaced.activityLevel()).isEqualTo(ActivityLevel.MODERATE);
        assertThat(replaced.minutesPerSession()).isEqualTo(45);
    }
}
