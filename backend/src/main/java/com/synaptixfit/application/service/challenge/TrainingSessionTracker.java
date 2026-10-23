package com.synaptixfit.application.service.challenge;

import com.synaptixfit.domain.model.challenge.Challenge;
import com.synaptixfit.domain.model.challenge.ChallengeChanges;
import com.synaptixfit.domain.port.output.challenge.ChallengeReferencePort;
import java.time.LocalDate;

/**
 * Aplica a un reto de fitness con objetivo de sesiones el recuento actual de entrenamientos de su
 * periodo (leído de Entrenamiento con {@link ChallengeReferencePort}). Lo comparten el alta y la
 * edición del reto y la sincronización por eventos.
 */
final class TrainingSessionTracker {

    private final ChallengeReferencePort references;

    TrainingSessionTracker(ChallengeReferencePort references) {
        this.references = references;
    }

    ChallengeChanges apply(Challenge challenge, LocalDate today) {
        if (!challenge.tracksTrainingSessions()) {
            return new ChallengeChanges();
        }
        int sessions = references.completedTrainingSessions(challenge.ownerId(), challenge.startAt(),
                challenge.endAt());
        return challenge.applyTrainingSessions(sessions, today);
    }
}
