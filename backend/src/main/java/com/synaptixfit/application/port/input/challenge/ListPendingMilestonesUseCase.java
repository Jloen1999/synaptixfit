package com.synaptixfit.application.port.input.challenge;

import com.synaptixfit.domain.model.challenge.PendingMilestone;
import java.util.List;
import java.util.UUID;

/** Tareas disponibles o en curso de los retos activos del usuario (agenda del día). */
public interface ListPendingMilestonesUseCase {

    List<PendingMilestone> listPendingMilestones(UUID userId);
}
