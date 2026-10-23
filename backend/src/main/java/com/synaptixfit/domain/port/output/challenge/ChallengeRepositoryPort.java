package com.synaptixfit.domain.port.output.challenge;

import com.synaptixfit.domain.model.challenge.Challenge;
import com.synaptixfit.domain.model.challenge.ChallengeQuery;
import com.synaptixfit.domain.model.challenge.ChallengeSummary;
import com.synaptixfit.domain.model.challenge.ProgressEntry;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/** Persistencia de retos con sus tareas ({@code retos}, {@code hitos_de_reto}, {@code progreso_de_reto}). */
public interface ChallengeRepositoryPort {

    Optional<Challenge> findById(UUID id);

    /** Guarda el reto y sincroniza su lista de tareas (altas, cambios y bajas). */
    Challenge save(Challenge challenge);

    void delete(UUID id);

    PageResult<Challenge> findByOwner(UUID ownerId, ChallengeQuery query, PageRequest page, Instant now);

    ChallengeSummary summarize(UUID ownerId, Instant now);

    /** Retos no completados y en plazo, ordenados por fecha de fin. */
    List<Challenge> findActiveByOwner(UUID ownerId, Instant now);

    /** Retos del usuario vinculados a la entidad, directamente o mediante alguna de sus tareas. */
    List<Challenge> findByLinkedEntity(UUID ownerId, UUID entityId);

    Optional<Challenge> findByMilestoneId(UUID milestoneId);

    /** Retos de fitness del usuario con objetivo de sesiones de entrenamiento (de cualquier estado). */
    List<Challenge> findTrainingTrackedByOwner(UUID ownerId);

    /** Retos del usuario no privados. */
    List<Challenge> findNonPrivateByOwner(UUID ownerId);

    ProgressEntry saveProgress(ProgressEntry entry);

    /** Registros de progreso del reto, del más reciente al más antiguo. */
    List<ProgressEntry> findProgress(UUID challengeId);
}
