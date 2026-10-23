package com.synaptixfit.application.port.input.challenge;

import com.synaptixfit.domain.model.challenge.Challenge;
import com.synaptixfit.domain.model.challenge.ChallengeType;
import com.synaptixfit.domain.model.challenge.Difficulty;
import com.synaptixfit.domain.model.challenge.LinkType;
import com.synaptixfit.domain.model.shared.Visibility;
import java.time.Instant;
import java.util.UUID;

/**
 * Edición parcial de los datos de un reto (no de sus tareas). Los campos nulos no cambian;
 * {@code clearSubject}, {@code clearLink} y {@code clearSessionTarget} quitan la asignatura, el
 * vínculo y el objetivo de sesiones de entrenamiento.
 */
public interface UpdateChallengeUseCase {

    record Command(UUID userId, UUID challengeId, String title, ChallengeType type, String goal,
                   Visibility visibility, Difficulty difficulty, Instant startAt, Instant endAt,
                   UUID subjectId, boolean clearSubject, LinkType linkType, UUID linkId, boolean clearLink,
                   Integer sessionTarget, boolean clearSessionTarget) {

        /** Edición sin cambios en el objetivo de sesiones. */
        public Command(UUID userId, UUID challengeId, String title, ChallengeType type, String goal,
                       Visibility visibility, Difficulty difficulty, Instant startAt, Instant endAt,
                       UUID subjectId, boolean clearSubject, LinkType linkType, UUID linkId, boolean clearLink) {
            this(userId, challengeId, title, type, goal, visibility, difficulty, startAt, endAt, subjectId,
                    clearSubject, linkType, linkId, clearLink, null, false);
        }
    }

    Challenge updateChallenge(Command command);
}
