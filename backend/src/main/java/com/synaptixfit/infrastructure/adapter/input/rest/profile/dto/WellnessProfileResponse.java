package com.synaptixfit.infrastructure.adapter.input.rest.profile.dto;

import com.synaptixfit.domain.model.profile.ActivityLevel;
import com.synaptixfit.domain.model.profile.Sex;
import com.synaptixfit.domain.model.profile.TrainingGoal;
import com.synaptixfit.domain.model.profile.WellnessProfile;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

/** Perfil de bienestar. {@code bmi} lo calcula el servidor; {@code primaryGoalLabel} es el texto en español. */
public record WellnessProfileResponse(UUID id, Integer age, Sex sex, String city, double weightKg, double heightCm,
                                      double bmi, ActivityLevel activityLevel, TrainingGoal primaryGoal,
                                      String primaryGoalLabel, List<String> goals, List<String> equipment,
                                      List<Integer> availableDays, int daysPerWeek, int minutesPerSession,
                                      boolean onboardingCompleted, Instant createdAt, Instant updatedAt) {

    public static WellnessProfileResponse from(WellnessProfile p) {
        return new WellnessProfileResponse(p.id(), p.age(), p.sex(), p.city(), p.weightKg(), p.heightCm(), p.bmi(),
                p.activityLevel(), p.primaryGoal(), p.primaryGoal().label(), p.goals(), p.equipment(),
                p.availableDays(), p.daysPerWeek(), p.minutesPerSession(), p.onboardingCompleted(), p.createdAt(),
                p.updatedAt());
    }
}
