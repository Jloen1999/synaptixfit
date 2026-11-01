package com.synaptixfit.application.service.challenge;

import com.synaptixfit.application.port.input.gamification.AwardExperienceUseCase;
import com.synaptixfit.application.port.input.gamification.RevokeExperienceUseCase;
import com.synaptixfit.domain.event.challenge.ChallengeCompleted;
import com.synaptixfit.domain.model.challenge.Challenge;
import com.synaptixfit.domain.model.challenge.ChallengeChanges;
import com.synaptixfit.domain.port.output.event.DomainEventPublisherPort;
import java.time.Clock;
import java.util.UUID;

/**
 * Propaga los efectos de una operación sobre un reto, ya guardado: aplica el XP neto y publica
 * {@link ChallengeCompleted}. No toca entregas ni exámenes vinculados: son la fuente de verdad y el reto
 * solo los sigue (ADR 0028).
 */
public class ChallengeEffects {

    private final AwardExperienceUseCase awardExperience;
    private final RevokeExperienceUseCase revokeExperience;
    private final DomainEventPublisherPort events;
    private final Clock clock;

    public ChallengeEffects(AwardExperienceUseCase awardExperience, RevokeExperienceUseCase revokeExperience,
                            DomainEventPublisherPort events, Clock clock) {
        this.awardExperience = awardExperience;
        this.revokeExperience = revokeExperience;
        this.events = events;
        this.clock = clock;
    }

    public void apply(Challenge challenge, ChallengeChanges changes) {
        UUID userId = challenge.ownerId();
        applyXp(userId, changes.xpDelta());
        if (changes.challengeCompleted()) {
            events.publish(new ChallengeCompleted(userId, challenge.id(), challenge.title(),
                    challenge.type().name(), clock.instant()));
        }
    }

    public void applyXp(UUID userId, int xpDelta) {
        if (xpDelta > 0) {
            awardExperience.award(userId, xpDelta);
        } else if (xpDelta < 0) {
            revokeExperience.revoke(userId, -xpDelta);
        }
    }
}
