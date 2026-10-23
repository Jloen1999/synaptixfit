package com.synaptixfit.infrastructure.adapter.input.rest.training;

import com.synaptixfit.application.port.input.training.GetExerciseFilterOptionsUseCase;
import com.synaptixfit.application.port.input.training.GetExerciseUseCase;
import com.synaptixfit.application.port.input.training.ListExerciseAlternativesUseCase;
import com.synaptixfit.application.port.input.training.SearchExercisesUseCase;
import com.synaptixfit.application.port.input.training.SuggestSessionBookendsUseCase;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.training.Difficulty;
import com.synaptixfit.domain.model.training.ExerciseCategory;
import com.synaptixfit.domain.model.training.ExerciseSearchCriteria;
import com.synaptixfit.domain.model.training.Modality;
import com.synaptixfit.domain.model.training.TrainingGoal;
import com.synaptixfit.infrastructure.adapter.input.rest.support.PageResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.training.dto.ExerciseDtos.ExerciseFilterOptionsResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.training.dto.ExerciseDtos.ExerciseResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.training.dto.ExerciseDtos.SessionBookendsResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.util.List;
import java.util.UUID;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/** Catálogo de ejercicios (solo activos). */
@Tag(name = "Exercises")
@RestController
@RequestMapping("/api/v1/exercises")
public class ExerciseController {

    private final SearchExercisesUseCase search;
    private final GetExerciseUseCase get;
    private final GetExerciseFilterOptionsUseCase filters;
    private final ListExerciseAlternativesUseCase alternatives;
    private final SuggestSessionBookendsUseCase bookends;

    public ExerciseController(SearchExercisesUseCase search, GetExerciseUseCase get,
                              GetExerciseFilterOptionsUseCase filters,
                              ListExerciseAlternativesUseCase alternatives, SuggestSessionBookendsUseCase bookends) {
        this.search = search;
        this.get = get;
        this.filters = filters;
        this.alternatives = alternatives;
        this.bookends = bookends;
    }

    /** Calentamiento (movilidad) y vuelta a la calma (estiramientos) para los ejercicios indicados. */
    @GetMapping("/bookends")
    public SessionBookendsResponse bookends(@RequestParam List<UUID> exerciseIds) {
        return SessionBookendsResponse.from(bookends.bookends(exerciseIds));
    }

    @GetMapping
    public PageResponse<ExerciseResponse> search(@RequestParam(required = false) String q,
                                                 @RequestParam(required = false) Integer bodyPartId,
                                                 @RequestParam(required = false) Integer muscleId,
                                                 @RequestParam(required = false) Integer equipmentId,
                                                 @RequestParam(required = false) Difficulty difficulty,
                                                 @RequestParam(required = false) Modality modality,
                                                 @RequestParam(required = false) TrainingGoal purpose,
                                                 @RequestParam(required = false) ExerciseCategory category,
                                                 @RequestParam(defaultValue = "0") int page,
                                                 @RequestParam(defaultValue = "20") int size) {
        return PageResponse.from(search.search(new ExerciseSearchCriteria(q, bodyPartId, muscleId, equipmentId,
                difficulty, modality, purpose, false, category), new PageRequest(page, size)), ExerciseResponse::from);
    }

    @GetMapping("/filters")
    public ExerciseFilterOptionsResponse filters() {
        return ExerciseFilterOptionsResponse.from(filters.filterOptions());
    }

    @GetMapping("/{exerciseId}")
    public ExerciseResponse get(@PathVariable UUID exerciseId) {
        return ExerciseResponse.from(get.get(exerciseId));
    }

    /** Ejercicios que pueden sustituir a este (mismo músculo principal), del más parecido al menos. */
    @GetMapping("/{exerciseId}/alternatives")
    public List<ExerciseResponse> alternatives(@PathVariable UUID exerciseId) {
        return alternatives.alternatives(exerciseId).stream().map(ExerciseResponse::from).toList();
    }
}
