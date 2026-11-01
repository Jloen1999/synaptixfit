package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.training.generation.LoadSuggestion;
import java.util.List;
import java.util.UUID;

/**
 * Propuesta de carga de hoy para cada ejercicio de una sesión propia en curso («Hoy prueba 42,5 kg»),
 * calculada desde la última vez que se hizo. Vacía en una sesión libre, terminada o abandonada.
 */
public interface GetLoadSuggestionsUseCase {

    List<LoadSuggestion> loadSuggestions(UUID userId, UUID sessionId);
}
