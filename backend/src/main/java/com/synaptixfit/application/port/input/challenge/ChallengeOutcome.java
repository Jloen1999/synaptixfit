package com.synaptixfit.application.port.input.challenge;

import com.synaptixfit.domain.model.challenge.Challenge;
import java.util.List;
import java.util.UUID;

/**
 * Resultado de una acción sobre un reto.
 *
 * @param xpDelta              experiencia neta aplicada (negativa si se ha restado)
 * @param unlockedMilestoneIds tareas que se han desbloqueado con la acción
 * @param challengeCompleted   el reto ha pasado a completado con la acción
 */
public record ChallengeOutcome(Challenge challenge, int xpDelta, List<UUID> unlockedMilestoneIds,
                               boolean challengeCompleted) {
}
