package com.synaptixfit.application.port.input.badge;

import java.util.UUID;

/**
 * Evalúa los criterios de todas las insignias pendientes y otorga las cumplidas (idempotente por
 * la restricción única). También actualiza la racha diaria del usuario.
 */
public interface EvaluateBadgesUseCase {

    BadgeEvaluation evaluateBadges(UUID userId, String zone);
}
