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

/**
 * Perfil de bienestar (crear o reemplazar). Días: 1 = lunes … 7 = domingo. Actividad, días y minutos
 * son opcionales (onboarding corto): sin ellos se usan los valores por defecto o se conservan.
 */
public record WellnessProfileRequest(
        @Min(15) @Max(80) Integer age,
        @NotNull Sex sex,
        @Size(max = 100) String city,
        @NotNull @DecimalMin("30") @DecimalMax("250") Double weightKg,
        @NotNull @DecimalMin("120") @DecimalMax("230") Double heightCm,
        ActivityLevel activityLevel,
        @NotNull TrainingGoal primaryGoal,
        @Size(max = 10) List<@Size(max = 100) String> goals,
        @Size(max = 30) List<@Size(max = 50) String> equipment,
        @Size(max = 7) List<@NotNull @Min(1) @Max(7) Integer> availableDays,
        @Min(10) @Max(180) Integer minutesPerSession) {
}
