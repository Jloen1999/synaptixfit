package com.synaptixfit.infrastructure.adapter.input.rest.profile.dto;

import com.synaptixfit.domain.model.profile.ActivityLevel;
import com.synaptixfit.domain.model.profile.Sex;
import com.synaptixfit.domain.model.profile.TrainingGoal;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.util.List;

/** Edición parcial del perfil de bienestar: los campos nulos no cambian; {@code city} vacía la borra. */
public record WellnessProfilePatchRequest(
        @Min(15) @Max(80) Integer age,
        Sex sex,
        @Size(max = 100) String city,
        @DecimalMin("30") @DecimalMax("250") Double weightKg,
        @DecimalMin("120") @DecimalMax("230") Double heightCm,
        ActivityLevel activityLevel,
        TrainingGoal primaryGoal,
        @Size(max = 10) List<@Size(max = 100) String> goals,
        @Size(max = 30) List<@Size(max = 50) String> equipment,
        @Size(min = 1, max = 7) List<@NotNull @Min(1) @Max(7) Integer> availableDays,
        @Min(10) @Max(180) Integer minutesPerSession) {
}
