package com.synaptixfit.infrastructure.adapter.input.rest.badge.dto;

import com.synaptixfit.application.port.input.badge.BadgeEvaluation;
import java.util.List;

/** Insignias recién obtenidas en esta evaluación y racha diaria actualizada. */
public record BadgeEvaluationResponse(List<BadgeResponse> newlyEarned, StreakResponse streak) {

    public static BadgeEvaluationResponse from(BadgeEvaluation e) {
        return new BadgeEvaluationResponse(e.newlyEarned().stream().map(BadgeResponse::from).toList(),
                StreakResponse.from(e.streak()));
    }
}
