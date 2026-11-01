package com.synaptixfit.domain.port.output.training;

import com.synaptixfit.domain.model.shared.AuthorAudience;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import com.synaptixfit.domain.model.training.VisibleRoutine;
import com.synaptixfit.domain.model.training.Routine;
import com.synaptixfit.domain.model.training.RoutineStatus;
import com.synaptixfit.domain.model.training.TrainingGoal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/** Persistencia del agregado rutina (semanas, días y ejercicios planificados). */
public interface RoutineRepositoryPort {

    /** Rutina no eliminada con toda su estructura. */
    Optional<Routine> findById(UUID id);

    /** Guarda el agregado completo, sincronizando semanas, días y ejercicios. */
    Routine save(Routine routine);

    PageResult<Routine> findByOwner(UUID ownerId, RoutineStatus status, PageRequest page);

    List<Routine> findAllByOwner(UUID ownerId);

    /** La rutina activa más reciente del usuario. */
    Optional<Routine> findLatestActive(UUID ownerId);

    /** Todas las rutinas activas (no borradas) del usuario; normalmente una (o ninguna). */
    List<Routine> findActiveByOwner(UUID ownerId);

    /**
     * Rutinas de otros usuarios visibles para {@code viewerId} según {@code EffectiveVisibility}
     * (visibilidad de la rutina y del perfil, bloqueos, autores eliminados o con shadowban).
     */
    PageResult<VisibleRoutine> findCommunity(UUID viewerId, String text, TrainingGoal goal, PageRequest page);

    /** Rutina no borrada con su autor y los datos de este vistos por {@code viewerId}, sin decidir nada. */
    record AuthoredRoutine(Routine routine, String authorName, AuthorAudience audience) {
    }

    /**
     * Cualquier rutina no borrada con los datos de su autor vistos por {@code viewerId}; quién puede
     * verla lo decide el caso de uso con {@code EffectiveVisibility}.
     */
    Optional<AuthoredRoutine> findWithAuthor(UUID routineId, UUID viewerId);
}
