package com.synaptixfit.application.service.challenge;

import com.synaptixfit.domain.model.challenge.ActivityFact;
import com.synaptixfit.domain.model.challenge.Challenge;
import com.synaptixfit.domain.model.challenge.ChallengeChanges;
import com.synaptixfit.domain.model.challenge.ChallengeRule;
import com.synaptixfit.domain.port.output.challenge.ChallengeReferencePort;
import java.time.Duration;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.List;

/**
 * Aplica a un reto con regla automática (ADR 0043) lo que la persona ha hecho en su periodo, leído de otros módulos
 * con {@link ChallengeReferencePort}; qué cuenta lo decide {@link ChallengeRule#count}. Lo comparten el alta, la
 * edición y la sincronización por eventos.
 */
final class RuleTracker {

    /** Margen para lo que solo tiene fecha (registro diario, semana planificada): la regla ya filtra por día. */
    private static final Duration DAY_MARGIN = Duration.ofDays(1);

    private final ChallengeReferencePort references;
    private final ZoneId zone;

    RuleTracker(ChallengeReferencePort references, ZoneId zone) {
        this.references = references;
        this.zone = zone;
    }

    ChallengeChanges apply(Challenge challenge, LocalDate today) {
        if (!challenge.tracksRule()) {
            return new ChallengeChanges();
        }
        ChallengeRule rule = challenge.rule();
        List<ActivityFact> facts = references.activity(challenge.ownerId(), rule.metric().sources(),
                challenge.startAt().minus(DAY_MARGIN), challenge.endAt().plus(DAY_MARGIN));
        return challenge.applyRule(rule.count(facts, challenge.startAt(), challenge.endAt(), zone), today);
    }
}
