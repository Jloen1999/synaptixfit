package com.synaptixfit.application.service.training;

import com.synaptixfit.application.port.input.training.AdminGetExerciseUseCase;
import com.synaptixfit.application.port.input.training.AdminSearchExercisesUseCase;
import com.synaptixfit.application.port.input.training.CreateExerciseUseCase;
import com.synaptixfit.application.port.input.training.DeleteExerciseUseCase;
import com.synaptixfit.application.port.input.training.GetExerciseFilterOptionsUseCase;
import com.synaptixfit.application.port.input.training.GetExerciseUseCase;
import com.synaptixfit.application.port.input.training.ListExerciseAlternativesUseCase;
import com.synaptixfit.application.port.input.training.SearchExercisesUseCase;
import com.synaptixfit.application.port.input.training.SetExerciseActiveUseCase;
import com.synaptixfit.application.port.input.training.SuggestSessionBookendsUseCase;
import com.synaptixfit.application.port.input.training.UpdateExerciseUseCase;
import com.synaptixfit.domain.exception.training.CatalogReferenceInvalidException;
import com.synaptixfit.domain.exception.training.ExerciseNotFoundException;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import com.synaptixfit.domain.model.training.CatalogItem;
import com.synaptixfit.domain.model.training.Exercise;
import com.synaptixfit.domain.model.training.ExerciseAlternatives;
import com.synaptixfit.domain.model.training.ExerciseCategory;
import com.synaptixfit.domain.model.training.ExerciseDraft;
import com.synaptixfit.domain.model.training.ExerciseFilterOptions;
import com.synaptixfit.domain.model.training.ExerciseSearchCriteria;
import com.synaptixfit.domain.model.training.SessionBookends;
import com.synaptixfit.domain.port.output.training.ExerciseNameTranslationsRepositoryPort;
import com.synaptixfit.domain.port.output.training.ExerciseRepositoryPort;
import java.time.Clock;
import java.util.Arrays;
import java.util.EnumSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

/**
 * Catálogo de ejercicios: consulta para usuarios (solo activos) y gestión de administración. Un
 * ejercicio usado en alguna rutina no se borra (la FK lo impide y romperíamos rutinas): se desactiva.
 * Al crear o editar se guardan también sus nombres en otros idiomas, en la misma transacción.
 */
public class ExerciseCatalogService implements SearchExercisesUseCase, GetExerciseUseCase, ListExerciseAlternativesUseCase,
        SuggestSessionBookendsUseCase,
        GetExerciseFilterOptionsUseCase, AdminSearchExercisesUseCase, AdminGetExerciseUseCase, CreateExerciseUseCase,
        UpdateExerciseUseCase, SetExerciseActiveUseCase, DeleteExerciseUseCase {

    private final ExerciseRepositoryPort exercises;
    private final ExerciseNameTranslationsRepositoryPort names;
    private final Clock clock;

    public ExerciseCatalogService(ExerciseRepositoryPort exercises, ExerciseNameTranslationsRepositoryPort names,
                                  Clock clock) {
        this.exercises = exercises;
        this.names = names;
        this.clock = clock;
    }

    @Override
    public PageResult<Exercise> search(ExerciseSearchCriteria criteria, PageRequest page) {
        ExerciseSearchCriteria c = criteria == null ? ExerciseSearchCriteria.all() : criteria;
        return exercises.search(new ExerciseSearchCriteria(c.text(), c.bodyPartId(), c.muscleId(), c.equipmentId(),
                c.difficulty(), c.modality(), c.purpose(), false, c.category()), page);
    }

    @Override
    public Exercise get(UUID exerciseId) {
        return exercises.findById(exerciseId).filter(Exercise::active)
                .orElseThrow(() -> new ExerciseNotFoundException(exerciseId));
    }

    /** Candidatos limitados: el ranking del dominio elige los más parecidos entre ellos. */
    static final int ALTERNATIVE_CANDIDATES = 200;

    /** Una sesión real no pasa de unos 15 ejercicios; el resto se ignora para acotar la consulta. */
    static final int MAX_SESSION_EXERCISES = 30;

    private static final Set<ExerciseCategory> BOOKEND_CATEGORIES = EnumSet.copyOf(
            Arrays.stream(ExerciseCategory.values()).filter(ExerciseCategory::isWarmUpOrCoolDown).toList());

    /**
     * Primero se buscan candidatos de la misma categoría (son los que mejor puntúan); si no llegan,
     * se completan con los de cualquier categoría que trabajen esos músculos.
     */
    @Override
    public List<Exercise> alternatives(UUID exerciseId) {
        Exercise base = get(exerciseId);
        List<Integer> muscles = base.targetMuscles().stream().map(CatalogItem::id).toList();
        Map<UUID, Exercise> pool = new LinkedHashMap<>();
        exercises.findActiveByTargetMuscles(muscles, EnumSet.of(base.category()), ALTERNATIVE_CANDIDATES)
                .forEach(e -> pool.put(e.id(), e));
        if (pool.size() <= ExerciseAlternatives.DEFAULT_LIMIT) {
            exercises.findActiveByTargetMuscles(muscles, Set.of(), ALTERNATIVE_CANDIDATES)
                    .forEach(e -> pool.putIfAbsent(e.id(), e));
        }
        return ExerciseAlternatives.rank(base, List.copyOf(pool.values()), ExerciseAlternatives.DEFAULT_LIMIT);
    }

    /** Movilidad y estiramientos de los músculos de la sesión; los candidatos se filtran ya en la consulta. */
    @Override
    public SessionBookends bookends(List<UUID> exerciseIds) {
        if (exerciseIds == null || exerciseIds.isEmpty()) {
            return new SessionBookends(List.of(), List.of());
        }
        List<UUID> ids = exerciseIds.stream().distinct().limit(MAX_SESSION_EXERCISES).toList();
        List<Exercise> session = List.copyOf(exercises.findByIds(ids).values());
        List<Exercise> candidates = exercises.findActiveByTargetMuscles(SessionBookends.targetMuscles(session),
                BOOKEND_CATEGORIES, ALTERNATIVE_CANDIDATES);
        return SessionBookends.of(session, candidates);
    }

    @Override
    public ExerciseFilterOptions filterOptions() {
        return exercises.filterOptions();
    }

    @Override
    public PageResult<Exercise> adminSearch(ExerciseSearchCriteria criteria, PageRequest page) {
        return exercises.search(criteria == null ? ExerciseSearchCriteria.all() : criteria, page);
    }

    @Override
    public Exercise adminGet(UUID exerciseId) {
        return exercises.findById(exerciseId).orElseThrow(() -> new ExerciseNotFoundException(exerciseId));
    }

    @Override
    public Exercise create(ExerciseDraft draft) {
        if (!exercises.catalogReferencesExist(draft)) {
            throw new CatalogReferenceInvalidException();
        }
        Exercise created = exercises.create(UUID.randomUUID(), draft, clock.instant());
        saveNames(created.id(), draft);
        return created;
    }

    @Override
    public Exercise update(UUID exerciseId, ExerciseDraft draft) {
        adminGet(exerciseId);
        if (!exercises.catalogReferencesExist(draft)) {
            throw new CatalogReferenceInvalidException();
        }
        Exercise updated = exercises.update(exerciseId, draft, clock.instant());
        saveNames(exerciseId, draft);
        return updated;
    }

    private void saveNames(UUID exerciseId, ExerciseDraft draft) {
        if (draft.translations() != null) {
            names.replace(exerciseId, draft.translations());
        }
    }

    @Override
    public Exercise setActive(UUID exerciseId, boolean active) {
        Exercise current = adminGet(exerciseId);
        if (current.active() != active) {
            exercises.setActive(exerciseId, active, clock.instant());
        }
        return adminGet(exerciseId);
    }

    @Override
    public Result delete(UUID exerciseId) {
        Exercise current = adminGet(exerciseId);
        if (exercises.isUsedInRoutines(exerciseId)) {
            if (current.active()) {
                exercises.setActive(exerciseId, false, clock.instant());
            }
            return new Result(false, true);
        }
        exercises.delete(exerciseId);
        return new Result(true, false);
    }
}
