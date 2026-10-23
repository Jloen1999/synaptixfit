package com.synaptixfit.application.port.input.challenge;

import com.synaptixfit.domain.model.challenge.Challenge;
import java.util.List;
import java.util.UUID;

/** Cambia el orden de las tareas de un reto. */
public interface ReorderMilestonesUseCase {

    Challenge reorderMilestones(UUID userId, UUID challengeId, List<UUID> orderedMilestoneIds);
}
