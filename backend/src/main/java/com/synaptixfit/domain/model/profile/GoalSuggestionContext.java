package com.synaptixfit.domain.model.profile;

/** Datos del usuario con los que se recomiendan objetivos. Todos opcionales. */
public record GoalSuggestionContext(Integer age, Sex sex, ActivityLevel activityLevel, String city) {
}
