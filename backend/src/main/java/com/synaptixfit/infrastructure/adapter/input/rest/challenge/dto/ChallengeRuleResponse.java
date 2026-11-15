package com.synaptixfit.infrastructure.adapter.input.rest.challenge.dto;

import com.synaptixfit.domain.model.challenge.ChallengeRule;
import com.synaptixfit.domain.model.challenge.RuleMetric;
import com.synaptixfit.domain.model.challenge.RuleUnit;

/**
 * Regla con la que se cuenta solo un reto (ADR 0043): «{@code perUnit} {@code metric} cada {@code unit},
 * {@code target} veces», de lunes a viernes si {@code weekdaysOnly}. {@code met}: lo ya cumplido (en un reto o en su
 * plantilla, 0). {@code privateOnly}: sale de datos de bienestar y no se comparte.
 */
public record ChallengeRuleResponse(RuleMetric metric, RuleUnit unit, int perUnit, int target, boolean weekdaysOnly,
                                    int met, boolean privateOnly) {

    /** {@code null} si no hay regla. */
    public static ChallengeRuleResponse of(ChallengeRule rule, int met) {
        return rule == null ? null : new ChallengeRuleResponse(rule.metric(), rule.unit(), rule.perUnit(),
                rule.target(), rule.weekdaysOnly(), met, rule.privateOnly());
    }
}
