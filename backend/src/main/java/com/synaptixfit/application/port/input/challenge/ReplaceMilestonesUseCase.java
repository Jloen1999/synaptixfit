package com.synaptixfit.application.port.input.challenge;

import com.synaptixfit.domain.model.challenge.MilestoneDraft;
import java.util.List;
import java.util.UUID;

/** Reemplaza la lista de tareas de un reto (conservando el progreso de las que mantienen su id). */
public interface ReplaceMilestonesUseCase {

    record Command(UUID userId, UUID challengeId, List<MilestoneDraft> milestones) {}

    ChallengeOutcome replaceMilestones(Command command);
}
