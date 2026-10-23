package com.synaptixfit.infrastructure.adapter.input.rest.training;

import com.synaptixfit.application.port.input.training.AdminGetExerciseUseCase;
import com.synaptixfit.application.port.input.training.AdminSearchExercisesUseCase;
import com.synaptixfit.application.port.input.training.CreateExerciseUseCase;
import com.synaptixfit.application.port.input.training.DeleteExerciseUseCase;
import com.synaptixfit.application.port.input.training.SetExerciseActiveUseCase;
import com.synaptixfit.application.port.input.training.UpdateExerciseUseCase;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.training.Difficulty;
import com.synaptixfit.domain.model.training.ExerciseSearchCriteria;
import com.synaptixfit.domain.model.training.Modality;
import com.synaptixfit.domain.model.training.TrainingGoal;
import com.synaptixfit.infrastructure.adapter.input.rest.support.PageResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.training.dto.ExerciseDtos.DeleteExerciseResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.training.dto.ExerciseDtos.ExerciseRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.training.dto.ExerciseDtos.ExerciseResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.training.dto.ExerciseDtos.SetActiveRequest;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/** Gestión del catálogo de ejercicios (rol ADMIN). */
@Tag(name = "Admin - Exercises")
@RestController
@RequestMapping("/api/v1/admin/exercises")
public class AdminExerciseController {

    private final AdminSearchExercisesUseCase search;
    private final AdminGetExerciseUseCase get;
    private final CreateExerciseUseCase create;
    private final UpdateExerciseUseCase update;
    private final SetExerciseActiveUseCase setActive;
    private final DeleteExerciseUseCase delete;

    public AdminExerciseController(AdminSearchExercisesUseCase search, AdminGetExerciseUseCase get,
                                   CreateExerciseUseCase create, UpdateExerciseUseCase update,
                                   SetExerciseActiveUseCase setActive, DeleteExerciseUseCase delete) {
        this.search = search;
        this.get = get;
        this.create = create;
        this.update = update;
        this.setActive = setActive;
        this.delete = delete;
    }

    @GetMapping
    public PageResponse<ExerciseResponse> search(@RequestParam(required = false) String q,
                                                 @RequestParam(required = false) Integer bodyPartId,
                                                 @RequestParam(required = false) Integer muscleId,
                                                 @RequestParam(required = false) Integer equipmentId,
                                                 @RequestParam(required = false) Difficulty difficulty,
                                                 @RequestParam(required = false) Modality modality,
                                                 @RequestParam(required = false) TrainingGoal purpose,
                                                 @RequestParam(defaultValue = "true") boolean includeInactive,
                                                 @RequestParam(defaultValue = "0") int page,
                                                 @RequestParam(defaultValue = "20") int size) {
        return PageResponse.from(search.adminSearch(new ExerciseSearchCriteria(q, bodyPartId, muscleId, equipmentId,
                difficulty, modality, purpose, includeInactive), new PageRequest(page, size)), ExerciseResponse::from);
    }

    @GetMapping("/{exerciseId}")
    public ExerciseResponse get(@PathVariable UUID exerciseId) {
        return ExerciseResponse.from(get.adminGet(exerciseId));
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public ExerciseResponse create(@Valid @RequestBody ExerciseRequest request) {
        return ExerciseResponse.from(create.create(request.toDraft()));
    }

    @PutMapping("/{exerciseId}")
    public ExerciseResponse update(@PathVariable UUID exerciseId, @Valid @RequestBody ExerciseRequest request) {
        return ExerciseResponse.from(update.update(exerciseId, request.toDraft()));
    }

    @PatchMapping("/{exerciseId}/active")
    public ExerciseResponse setActive(@PathVariable UUID exerciseId, @Valid @RequestBody SetActiveRequest request) {
        return ExerciseResponse.from(setActive.setActive(exerciseId, request.active()));
    }

    /** Borra el ejercicio; si alguna rutina lo usa, lo desactiva en su lugar. */
    @DeleteMapping("/{exerciseId}")
    public DeleteExerciseResponse delete(@PathVariable UUID exerciseId) {
        DeleteExerciseUseCase.Result result = delete.delete(exerciseId);
        return new DeleteExerciseResponse(result.deleted(), result.deactivated());
    }
}
