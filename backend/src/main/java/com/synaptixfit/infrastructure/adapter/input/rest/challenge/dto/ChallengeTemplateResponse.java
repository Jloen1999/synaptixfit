package com.synaptixfit.infrastructure.adapter.input.rest.challenge.dto;

import com.synaptixfit.domain.model.challenge.ChallengeTemplate;
import com.synaptixfit.domain.model.challenge.ChallengeType;
import com.synaptixfit.domain.model.challenge.Difficulty;
import java.util.UUID;

/**
 * Plantilla de reto: cuántos días dura, la regla con la que se cuenta solo y {@code running} si ya hay un reto
 * suyo sin terminar (entonces no se puede empezar otro).
 */
public record ChallengeTemplateResponse(UUID id, String code, String title, String goal, ChallengeType type,
                                        Difficulty difficulty, int xpReward, int days, ChallengeRuleResponse rule,
                                        boolean running) {
    public static ChallengeTemplateResponse from(ChallengeTemplate t, boolean running) {
        return new ChallengeTemplateResponse(t.id(), t.code(), t.title(), t.goal(), t.type(), t.difficulty(),
                t.difficulty().xp(), t.days(), ChallengeRuleResponse.of(t.rule(), 0), running);
    }
}
