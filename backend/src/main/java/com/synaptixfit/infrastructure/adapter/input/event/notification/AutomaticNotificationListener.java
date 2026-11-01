package com.synaptixfit.infrastructure.adapter.input.event.notification;

import com.synaptixfit.application.port.input.notification.NotifyAchievementUseCase;
import com.synaptixfit.application.port.input.notification.NotifyFatigueAlertUseCase;
import com.synaptixfit.domain.event.badge.BadgeEarned;
import com.synaptixfit.domain.event.challenge.ChallengeCompleted;
import com.synaptixfit.domain.event.gamification.LevelUp;
import com.synaptixfit.domain.event.insights.OvertrainingDetected;
import com.synaptixfit.domain.event.training.CheckInSubmitted;
import com.synaptixfit.domain.event.training.RoutineCompleted;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;

/**
 * Convierte logros y señales de fatiga de otros módulos en notificaciones. Solo traduce el evento al
 * caso de uso, que aplica las preferencias del usuario y evita duplicados.
 */
@Component
public class AutomaticNotificationListener {

    private final NotifyAchievementUseCase achievements;
    private final NotifyFatigueAlertUseCase fatigue;

    public AutomaticNotificationListener(NotifyAchievementUseCase achievements, NotifyFatigueAlertUseCase fatigue) {
        this.achievements = achievements;
        this.fatigue = fatigue;
    }

    @EventListener
    public void on(ChallengeCompleted event) {
        achievements.notifyAchievement(new NotifyAchievementUseCase.Command(event.userId(),
                NotifyAchievementUseCase.Kind.CHALLENGE_COMPLETED, event.title(), event.challengeId()));
    }

    @EventListener
    public void on(RoutineCompleted event) {
        achievements.notifyAchievement(new NotifyAchievementUseCase.Command(event.userId(),
                NotifyAchievementUseCase.Kind.ROUTINE_COMPLETED, event.routineName(), event.routineId()));
    }

    @EventListener
    public void on(BadgeEarned event) {
        achievements.notifyAchievement(new NotifyAchievementUseCase.Command(event.userId(),
                NotifyAchievementUseCase.Kind.BADGE_EARNED, event.badgeName(), event.badgeId()));
    }

    @EventListener
    public void on(LevelUp event) {
        achievements.notifyAchievement(new NotifyAchievementUseCase.Command(event.userId(),
                NotifyAchievementUseCase.Kind.LEVEL_UP, String.valueOf(event.level()), null));
    }

    @EventListener
    public void on(CheckInSubmitted event) {
        if (event.requiresAdaptation()) {
            fatigue.notifyFatigue(new NotifyFatigueAlertUseCase.Command(event.userId(),
                    NotifyFatigueAlertUseCase.Reason.CHECK_IN_ADAPTATION, null));
        }
    }

    @EventListener
    public void on(OvertrainingDetected event) {
        fatigue.notifyFatigue(new NotifyFatigueAlertUseCase.Command(event.userId(),
                NotifyFatigueAlertUseCase.Reason.OVERTRAINING, event.acwr()));
    }
}
