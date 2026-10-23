package com.synaptixfit.application.service.gamification;

import com.synaptixfit.application.port.input.gamification.AwardExperienceUseCase;
import com.synaptixfit.application.port.input.gamification.RevokeExperienceUseCase;
import com.synaptixfit.domain.event.gamification.LevelUp;
import com.synaptixfit.domain.exception.user.UserNotFoundException;
import com.synaptixfit.domain.model.user.ExperienceChange;
import com.synaptixfit.domain.model.user.User;
import com.synaptixfit.domain.port.output.event.DomainEventPublisherPort;
import com.synaptixfit.domain.port.output.user.UserRepositoryPort;
import java.time.Clock;
import java.util.UUID;

/**
 * Suma y resta de experiencia sobre la cuenta del usuario. Al subir de nivel publica {@link LevelUp}
 * (Notificaciones lo celebra); perder un nivel al restar XP no se anuncia.
 */
public class ExperienceService implements AwardExperienceUseCase, RevokeExperienceUseCase {

    private final UserRepositoryPort users;
    private final DomainEventPublisherPort events;
    private final Clock clock;

    public ExperienceService(UserRepositoryPort users, DomainEventPublisherPort events, Clock clock) {
        this.users = users;
        this.events = events;
        this.clock = clock;
    }

    @Override
    public ExperienceChange award(UUID userId, int amount) {
        User user = users.findById(userId).orElseThrow(() -> new UserNotFoundException(userId));
        ExperienceChange change = user.gainExperience(amount);
        if (change.xpDelta() != 0) {
            users.save(user);
        }
        if (change.leveledUp()) {
            events.publish(new LevelUp(userId, change.level(), clock.instant()));
        }
        return change;
    }

    @Override
    public ExperienceChange revoke(UUID userId, int amount) {
        User user = users.findById(userId).orElseThrow(() -> new UserNotFoundException(userId));
        ExperienceChange change = user.loseExperience(amount);
        if (change.xpDelta() != 0) {
            users.save(user);
        }
        return change;
    }
}
