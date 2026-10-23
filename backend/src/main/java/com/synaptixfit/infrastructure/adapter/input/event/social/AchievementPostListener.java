package com.synaptixfit.infrastructure.adapter.input.event.social;

import com.synaptixfit.application.port.input.social.PublishAchievementPostUseCase;
import com.synaptixfit.domain.event.badge.BadgeEarned;
import com.synaptixfit.domain.event.challenge.ChallengeCompleted;
import com.synaptixfit.domain.model.social.PostType;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;

/**
 * Publica en el muro los logros que la app antigua compartía automáticamente: retos completados e
 * insignias desbloqueadas. La visibilidad de la publicación la decide la privacidad del autor. El
 * caso de uso no repite la publicación si se vuelve a completar el mismo reto (idempotente).
 */
@Component
public class AchievementPostListener {

    private final PublishAchievementPostUseCase publish;

    public AchievementPostListener(PublishAchievementPostUseCase publish) {
        this.publish = publish;
    }

    @EventListener
    public void on(ChallengeCompleted event) {
        publish.publishAchievement(new PublishAchievementPostUseCase.Command(event.userId(),
                PostType.CHALLENGE_COMPLETED, "Ha completado el reto «" + event.title() + "»",
                "{\"challengeId\":\"" + event.challengeId() + "\"}"));
    }

    @EventListener
    public void on(BadgeEarned event) {
        publish.publishAchievement(new PublishAchievementPostUseCase.Command(event.userId(), PostType.BADGE_UNLOCKED,
                "Ha desbloqueado la insignia «" + event.badgeName() + "»", "{\"badgeId\":\"" + event.badgeId() + "\"}"));
    }
}
