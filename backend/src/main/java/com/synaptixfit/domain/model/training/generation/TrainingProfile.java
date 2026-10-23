package com.synaptixfit.domain.model.training.generation;

import com.synaptixfit.domain.model.training.TrainingGoal;
import java.util.List;

/**
 * Datos del perfil de bienestar que usa el generador de rutinas (lo mantiene el módulo de perfil;
 * aquí solo se lee).
 */
public record TrainingProfile(int age, String sex, double weightKg, double heightCm, double bmi,
                              ActivityLevel activityLevel, TrainingGoal goal, List<String> equipment,
                              int daysPerWeek, int minutesPerSession, List<Integer> availableDays) {

    public TrainingProfile {
        equipment = List.copyOf(equipment == null ? List.of() : equipment);
        availableDays = List.copyOf(availableDays == null ? List.of() : availableDays);
        activityLevel = activityLevel == null ? ActivityLevel.LIGHT : activityLevel;
        goal = goal == null ? TrainingGoal.HYPERTROPHY : goal;
        daysPerWeek = Math.max(1, Math.min(7, daysPerWeek));
        minutesPerSession = Math.max(10, Math.min(180, minutesPerSession));
    }

    /**
     * Números de día (1-7) de la semana de entrenamiento: los días disponibles del perfil si
     * coinciden con los días por semana; si no, 1..n.
     */
    public List<Integer> trainingDayNumbers() {
        List<Integer> valid = availableDays.stream().filter(d -> d >= 1 && d <= 7).distinct().sorted().toList();
        if (valid.size() == daysPerWeek) {
            return valid;
        }
        return java.util.stream.IntStream.rangeClosed(1, daysPerWeek).boxed().toList();
    }
}
