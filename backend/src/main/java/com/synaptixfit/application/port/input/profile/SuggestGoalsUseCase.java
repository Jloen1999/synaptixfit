package com.synaptixfit.application.port.input.profile;

import com.synaptixfit.domain.model.profile.ActivityLevel;
import com.synaptixfit.domain.model.profile.GoalSuggestions;
import com.synaptixfit.domain.model.profile.Sex;
import java.util.UUID;

/**
 * Recomienda objetivos principales. Los datos no enviados se toman del perfil de bienestar si
 * existe (así sirve también durante el onboarding, antes de guardarlo). Si la IA falla se usan
 * las reglas deterministas.
 */
public interface SuggestGoalsUseCase {

    record Command(UUID userId, Integer age, Sex sex, ActivityLevel activityLevel, String city) {}

    GoalSuggestions suggestGoals(Command command);
}
