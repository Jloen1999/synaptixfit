package com.synaptixfit.domain.port.output.insights;

import com.synaptixfit.domain.model.insights.CognitiveState;
import java.util.Optional;
import java.util.UUID;

/** Estado cognitivo 1:1 con el usuario ({@code estado_cognitivo_usuario}). */
public interface CognitiveStateRepositoryPort {

    Optional<CognitiveState> findByUser(UUID userId);

    CognitiveState save(CognitiveState state);
}
