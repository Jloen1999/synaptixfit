package com.synaptixfit.infrastructure.adapter.input.event.gamification;

import com.synaptixfit.application.port.input.badge.EvaluateBadgesUseCase;
import com.synaptixfit.domain.event.academic.ReviewCompleted;
import com.synaptixfit.domain.event.academic.TestSessionCompleted;
import com.synaptixfit.domain.event.challenge.ChallengeCompleted;
import com.synaptixfit.domain.event.planner.DeadlineCompletionChanged;
import com.synaptixfit.domain.event.planner.FocusSessionCompleted;
import com.synaptixfit.domain.event.planner.StudyBlockCompletionChanged;
import com.synaptixfit.domain.event.training.CheckInSubmitted;
import com.synaptixfit.domain.event.training.TrainingSessionCompletionChanged;
import java.util.UUID;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;

/**
 * Evalúa las insignias y la racha en el servidor cada vez que el usuario hace algo que puede
 * cumplir un criterio, en lugar de esperar a que el cliente llame a {@code POST /badges/evaluate}
 * (que sigue existiendo). Solo traduce el evento al caso de uso, idempotente por la restricción
 * única de {@code usuario_insignias}; el cliente ve las nuevas en {@code /badges/unnotified}.
 * Los desmarcados no se escuchan: una insignia obtenida no se retira.
 */
@Component
public class BadgeEvaluationListener {

    private final EvaluateBadgesUseCase evaluateBadges;

    public BadgeEvaluationListener(EvaluateBadgesUseCase evaluateBadges) {
        this.evaluateBadges = evaluateBadges;
    }

    @EventListener
    public void on(ChallengeCompleted event) {
        evaluate(event.userId());
    }

    @EventListener
    public void on(TrainingSessionCompletionChanged event) {
        if (event.completed()) {
            evaluate(event.userId());
        }
    }

    @EventListener
    public void on(StudyBlockCompletionChanged event) {
        if (event.completed()) {
            evaluate(event.userId());
        }
    }

    @EventListener
    public void on(DeadlineCompletionChanged event) {
        if (event.completed()) {
            evaluate(event.userId());
        }
    }

    @EventListener
    public void on(FocusSessionCompleted event) {
        evaluate(event.userId());
    }

    @EventListener
    public void on(TestSessionCompleted event) {
        evaluate(event.userId());
    }

    @EventListener
    public void on(ReviewCompleted event) {
        evaluate(event.userId());
    }

    @EventListener
    public void on(CheckInSubmitted event) {
        evaluate(event.userId());
    }

    /** Zona nula: la de gamificación por defecto (la misma con la que se fechan rachas y retos). */
    private void evaluate(UUID userId) {
        evaluateBadges.evaluateBadges(userId, null);
    }
}
