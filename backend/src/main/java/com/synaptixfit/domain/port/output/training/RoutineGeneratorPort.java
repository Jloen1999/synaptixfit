package com.synaptixfit.domain.port.output.training;

import com.synaptixfit.domain.model.training.generation.RoutineRefinement;
import com.synaptixfit.domain.model.training.generation.RoutineRefinementRequest;

/**
 * Modelo generativo que refina una semana tipo generada por reglas (nombres, sustituciones y
 * orden). Lanza AiUnavailableException o AiQuotaExceededException si no puede responder.
 */
public interface RoutineGeneratorPort {

    RoutineRefinement refine(RoutineRefinementRequest request);
}
