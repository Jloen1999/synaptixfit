package com.synaptixfit.domain.port.output.challenge;

import com.synaptixfit.domain.model.challenge.ActivityFact;
import com.synaptixfit.domain.model.challenge.ActivityKind;
import java.util.List;
import com.synaptixfit.domain.model.challenge.RoutineDayTarget;
import com.synaptixfit.domain.model.challenge.StudyBlockProgress;
import java.time.Instant;
import java.util.Set;
import java.util.UUID;

/** Comprueba la propiedad de elementos de otros módulos que un reto referencia (solo lectura). */
public interface ChallengeReferencePort {

    boolean subjectBelongsTo(UUID userId, UUID subjectId);

    boolean deadlineBelongsTo(UUID userId, UUID deadlineId);

    /** El día pertenece a una rutina (no borrada) del usuario. */
    boolean routineDayBelongsTo(UUID userId, UUID routineDayId);

    /** Días de la rutina en curso del usuario, en orden, con su estado (Entrenamiento, solo lectura). */
    List<RoutineDayTarget> routineDayTargets(UUID userId);

    boolean noteBelongsTo(UUID userId, UUID noteId);

    boolean fileBelongsTo(UUID userId, UUID fileId);

    /** Bloques del calendario del usuario vinculados a la tarea. */
    StudyBlockProgress studyBlockProgress(UUID userId, UUID milestoneId);

    /** Sesiones de entrenamiento completadas por el usuario con fecha de fin en [from, to]. */
    int completedTrainingSessions(UUID userId, Instant from, Instant to);

    /**
     * Lo hecho por el usuario de esos tipos entre {@code from} y {@code to} (con un día de margen para lo que solo
     * tiene fecha), para los retos que se cuentan solos (ADR 0043). Solo trae datos: qué cuenta lo decide
     * {@code ChallengeRule}.
     */
    List<ActivityFact> activity(UUID userId, Set<ActivityKind> kinds, Instant from, Instant to);
}
