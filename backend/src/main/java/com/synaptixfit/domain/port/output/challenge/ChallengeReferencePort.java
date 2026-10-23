package com.synaptixfit.domain.port.output.challenge;

import com.synaptixfit.domain.model.challenge.StudyBlockProgress;
import java.time.Instant;
import java.util.UUID;

/** Comprueba la propiedad de elementos de otros módulos que un reto referencia (solo lectura). */
public interface ChallengeReferencePort {

    boolean subjectBelongsTo(UUID userId, UUID subjectId);

    boolean deadlineBelongsTo(UUID userId, UUID deadlineId);

    boolean studyBlockBelongsTo(UUID userId, UUID blockId);

    boolean noteBelongsTo(UUID userId, UUID noteId);

    boolean fileBelongsTo(UUID userId, UUID fileId);

    /** Bloques del calendario del usuario vinculados a la tarea. */
    StudyBlockProgress studyBlockProgress(UUID userId, UUID milestoneId);

    /** Sesiones de entrenamiento completadas por el usuario con fecha de fin en [from, to]. */
    int completedTrainingSessions(UUID userId, Instant from, Instant to);
}
