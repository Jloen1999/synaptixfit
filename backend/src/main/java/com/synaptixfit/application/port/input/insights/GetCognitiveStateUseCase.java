package com.synaptixfit.application.port.input.insights;

import com.synaptixfit.domain.model.insights.CognitiveState;
import java.util.UUID;

/**
 * Estado cognitivo actual, recalculado en memoria con la actividad de hoy. Es una lectura: no guarda
 * nada (el estado guardado lo actualiza {@link RefreshCognitiveStateUseCase} con los eventos).
 */
public interface GetCognitiveStateUseCase {

    CognitiveState getCognitiveState(UUID userId, String timeZone);
}
