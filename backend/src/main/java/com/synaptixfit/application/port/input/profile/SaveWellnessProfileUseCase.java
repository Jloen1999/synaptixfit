package com.synaptixfit.application.port.input.profile;

import com.synaptixfit.domain.model.profile.ActivityLevel;
import com.synaptixfit.domain.model.profile.Sex;
import com.synaptixfit.domain.model.profile.TrainingGoal;
import com.synaptixfit.domain.model.profile.WellnessProfile;
import java.util.List;
import java.util.UUID;

/**
 * Crea o reemplaza el perfil de bienestar completo (onboarding físico). Registra el peso en el
 * historial si cambia (o al crear) y abre o rota el periodo del historial de objetivos. Nivel de
 * actividad, días y minutos son opcionales: al crear se usan los valores por defecto de
 * {@code WellnessProfile} y al reemplazar se conservan los que había.
 */
public interface SaveWellnessProfileUseCase {

    record Command(UUID userId, int age, Sex sex, String city, double weightKg, double heightCm,
                   ActivityLevel activityLevel, TrainingGoal primaryGoal, List<String> goals, List<String> equipment,
                   List<Integer> availableDays, Integer minutesPerSession) {}

    WellnessProfile saveWellnessProfile(Command command);
}
