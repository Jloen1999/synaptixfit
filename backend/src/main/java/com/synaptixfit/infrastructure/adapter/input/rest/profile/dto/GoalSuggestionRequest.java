package com.synaptixfit.infrastructure.adapter.input.rest.profile.dto;

import com.synaptixfit.domain.model.profile.ActivityLevel;
import com.synaptixfit.domain.model.profile.Sex;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Size;

/** Datos opcionales para recomendar objetivos; lo que falte se toma del perfil guardado. */
public record GoalSuggestionRequest(@Min(15) @Max(80) Integer age, Sex sex, ActivityLevel activityLevel,
                                    @Size(max = 100) String city) {
}
