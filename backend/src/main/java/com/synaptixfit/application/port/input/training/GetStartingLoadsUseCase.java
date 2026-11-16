package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.training.TemplateLevel;
import java.util.Collection;
import java.util.Map;
import java.util.UUID;

/** Peso de partida «para probar» de cada ejercicio para una persona (ADR 0054). */
public interface GetStartingLoadsUseCase {

    /** Kilos por ejercicio; los que no llevan peso de partida (máquinas, peso corporal…) no aparecen. */
    Map<UUID, Double> startingLoads(UUID userId, Collection<UUID> exerciseIds, TemplateLevel level);
}
