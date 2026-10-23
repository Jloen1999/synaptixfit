package com.synaptixfit.application.port.input.profile;

import com.synaptixfit.domain.model.profile.ActivityLevel;
import com.synaptixfit.domain.model.profile.Sex;
import com.synaptixfit.domain.model.profile.TrainingGoal;
import com.synaptixfit.domain.model.profile.WellnessProfile;
import java.util.List;
import java.util.UUID;

/**
 * Edición parcial del perfil de bienestar: los campos nulos no cambian ({@code city} vacía la
 * borra). Un cambio de peso o altura se registra en el historial de peso; un cambio de objetivo
 * principal, en el historial de objetivos.
 */
public interface UpdateWellnessProfileUseCase {

    record Command(UUID userId, Integer age, Sex sex, String city, Double weightKg, Double heightCm,
                   ActivityLevel activityLevel, TrainingGoal primaryGoal, List<String> goals, List<String> equipment,
                   List<Integer> availableDays, Integer minutesPerSession) {}

    WellnessProfile updateWellnessProfile(Command command);
}
