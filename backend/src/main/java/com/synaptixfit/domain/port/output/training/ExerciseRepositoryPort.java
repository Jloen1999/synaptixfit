package com.synaptixfit.domain.port.output.training;

import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import com.synaptixfit.domain.model.training.Exercise;
import com.synaptixfit.domain.model.training.ExerciseCategory;
import com.synaptixfit.domain.model.training.ExerciseDraft;
import com.synaptixfit.domain.model.training.ExerciseFilterOptions;
import com.synaptixfit.domain.model.training.ExerciseSearchCriteria;
import java.time.Instant;
import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

/** Catálogo de ejercicios y sus tablas auxiliares (músculos, partes del cuerpo, equipamiento). */
public interface ExerciseRepositoryPort {

    PageResult<Exercise> search(ExerciseSearchCriteria criteria, PageRequest page);

    /** Cualquier ejercicio (activo o no). */
    Optional<Exercise> findById(UUID id);

    Map<UUID, Exercise> findByIds(Collection<UUID> ids);

    List<Exercise> findAllActive();

    /**
     * Ejercicios activos que tienen alguno de esos músculos como principal y, si {@code categories}
     * no está vacío, de una de esas categorías. Como mucho {@code limit}, primero los que tienen
     * vídeo (el catálogo original, mejor descrito). Son candidatos: el dominio decide el orden final.
     */
    List<Exercise> findActiveByTargetMuscles(Collection<Integer> muscleIds, Set<ExerciseCategory> categories,
            int limit);

    ExerciseFilterOptions filterOptions();

    /** Comprueba que existen todos los músculos, partes del cuerpo y equipamientos del borrador. */
    boolean catalogReferencesExist(ExerciseDraft draft);

    Exercise create(UUID id, ExerciseDraft draft, Instant now);

    Exercise update(UUID id, ExerciseDraft draft, Instant now);

    void setActive(UUID id, boolean active, Instant now);

    /** Si algún ejercicio planificado de alguna rutina lo usa. */
    boolean isUsedInRoutines(UUID id);

    void delete(UUID id);
}
