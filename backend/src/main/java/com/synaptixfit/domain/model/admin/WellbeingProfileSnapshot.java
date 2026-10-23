package com.synaptixfit.domain.model.admin;

/** Datos del perfil de bienestar visibles en el panel (textos tal como se almacenan). */
public record WellbeingProfileSnapshot(int age, String sex, Double weightKg, Double heightCm, Double bmi,
                                       String activityLevel, String mainGoal, int availableDaysPerWeek,
                                       int minutesPerSession, boolean onboardingCompleted) {
}
