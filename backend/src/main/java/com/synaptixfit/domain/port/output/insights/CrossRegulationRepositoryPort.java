package com.synaptixfit.domain.port.output.insights;

import com.synaptixfit.domain.model.insights.CrossRegulationState;
import java.util.Optional;
import java.util.UUID;

/** Caché del estado de regulación cruzada ({@code estado_regulacion_cruzada}). */
public interface CrossRegulationRepositoryPort {

    Optional<CrossRegulationState> findByUser(UUID userId);

    CrossRegulationState save(CrossRegulationState state);
}
