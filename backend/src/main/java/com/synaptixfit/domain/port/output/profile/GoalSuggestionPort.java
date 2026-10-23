package com.synaptixfit.domain.port.output.profile;

import com.synaptixfit.domain.model.profile.GoalSuggestion;
import com.synaptixfit.domain.model.profile.GoalSuggestionContext;
import java.util.List;

/**
 * Recomendación de objetivo principal con IA. Lanza {@code AiUnavailableException} o
 * {@code AiQuotaExceededException} si el modelo falla o responde algo inutilizable.
 */
public interface GoalSuggestionPort {

    /** Entre 1 y 3 objetivos estándar ordenados por adecuación. */
    List<GoalSuggestion> suggest(GoalSuggestionContext context);
}
