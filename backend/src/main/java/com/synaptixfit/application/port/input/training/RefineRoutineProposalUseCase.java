package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.training.generation.RoutineProposal;
import java.util.UUID;

/** Refina con IA una propuesta (posiblemente editada). Si la IA falla la devuelve igual con un aviso. */
public interface RefineRoutineProposalUseCase {

    RoutineProposal refine(UUID userId, RoutineProposal proposal);
}
