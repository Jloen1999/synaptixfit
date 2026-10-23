package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.training.TrainingGoal;
import com.synaptixfit.domain.model.training.generation.RoutineProposal;
import java.util.UUID;

/** Genera una propuesta de rutina (reglas + contexto + IA opcional). No la guarda. */
public interface GenerateRoutineProposalUseCase {

    RoutineProposal generate(Command command);

    /** {@code goal} nulo usa el objetivo del perfil. */
    record Command(UUID userId, int durationWeeks, TrainingGoal goal, boolean useAi) {
    }
}
