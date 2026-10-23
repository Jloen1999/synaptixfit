package com.synaptixfit.infrastructure.adapter.input.rest.training;

import com.synaptixfit.application.port.input.training.AddRoutineDayUseCase;
import com.synaptixfit.application.port.input.training.AddRoutineExerciseUseCase;
import com.synaptixfit.application.port.input.training.AddRoutineWeekUseCase;
import com.synaptixfit.application.port.input.training.ChangeRoutineStatusUseCase;
import com.synaptixfit.application.port.input.training.CloneRoutineUseCase;
import com.synaptixfit.application.port.input.training.CreateRoutineUseCase;
import com.synaptixfit.application.port.input.training.DeleteRoutineDayUseCase;
import com.synaptixfit.application.port.input.training.DeleteRoutineUseCase;
import com.synaptixfit.application.port.input.training.DeleteRoutineWeekUseCase;
import com.synaptixfit.application.port.input.training.DuplicateRoutineUseCase;
import com.synaptixfit.application.port.input.training.GenerateRoutineProposalUseCase;
import com.synaptixfit.application.port.input.training.GetRoutineUseCase;
import com.synaptixfit.application.port.input.training.ListCommunityRoutinesUseCase;
import com.synaptixfit.application.port.input.training.ListMyRoutinesUseCase;
import com.synaptixfit.application.port.input.training.RefineRoutineProposalUseCase;
import com.synaptixfit.application.port.input.training.RemoveRoutineExerciseUseCase;
import com.synaptixfit.application.port.input.training.RenameRoutineDayUseCase;
import com.synaptixfit.application.port.input.training.ReorderRoutineExercisesUseCase;
import com.synaptixfit.application.port.input.training.UpdateRoutineExerciseUseCase;
import com.synaptixfit.application.port.input.training.UpdateRoutineUseCase;
import com.synaptixfit.application.port.input.training.UpdateRoutineWeekUseCase;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.training.Routine;
import com.synaptixfit.domain.model.training.RoutineStatus;
import com.synaptixfit.domain.model.training.TrainingGoal;
import com.synaptixfit.domain.model.training.VisibleRoutine;
import com.synaptixfit.infrastructure.adapter.input.rest.support.CurrentUserId;
import com.synaptixfit.infrastructure.adapter.input.rest.support.PageResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.training.dto.ProposalDtos.GenerateRoutineRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.training.dto.ProposalDtos.RoutineProposalDto;
import com.synaptixfit.infrastructure.adapter.input.rest.training.dto.RoutineDtos.AddDayRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.training.dto.RoutineDtos.ChangeRoutineStatusRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.training.dto.RoutineDtos.CreateRoutineRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.training.dto.RoutineDtos.DuplicateRoutineRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.training.dto.RoutineDtos.ExerciseParametersRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.training.dto.RoutineDtos.PlannedExerciseRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.training.dto.RoutineDtos.RenameDayRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.training.dto.RoutineDtos.ReorderExercisesRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.training.dto.RoutineDtos.RoutineResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.training.dto.RoutineDtos.RoutineSummaryResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.training.dto.RoutineDtos.UpdateRoutineRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.training.dto.RoutineDtos.WeekChangeRequest;
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

/** Rutinas: CRUD, estructura (semanas, días, ejercicios), comunidad y generación. */
@Tag(name = "Routines")
@RestController
@RequestMapping("/api/v1/routines")
public class RoutineController {

    private final CreateRoutineUseCase create;
    private final GetRoutineUseCase get;
    private final ListMyRoutinesUseCase listMine;
    private final ListCommunityRoutinesUseCase listCommunity;
    private final UpdateRoutineUseCase update;
    private final ChangeRoutineStatusUseCase changeStatus;
    private final DeleteRoutineUseCase delete;
    private final DuplicateRoutineUseCase duplicate;
    private final CloneRoutineUseCase cloneRoutine;
    private final AddRoutineWeekUseCase addWeek;
    private final UpdateRoutineWeekUseCase updateWeek;
    private final DeleteRoutineWeekUseCase deleteWeek;
    private final AddRoutineDayUseCase addDay;
    private final RenameRoutineDayUseCase renameDay;
    private final DeleteRoutineDayUseCase deleteDay;
    private final AddRoutineExerciseUseCase addExercise;
    private final UpdateRoutineExerciseUseCase updateExercise;
    private final RemoveRoutineExerciseUseCase removeExercise;
    private final ReorderRoutineExercisesUseCase reorder;
    private final GenerateRoutineProposalUseCase generate;
    private final RefineRoutineProposalUseCase refine;

    @SuppressWarnings("java:S107")
    public RoutineController(CreateRoutineUseCase create, GetRoutineUseCase get, ListMyRoutinesUseCase listMine,
                             ListCommunityRoutinesUseCase listCommunity, UpdateRoutineUseCase update,
                             ChangeRoutineStatusUseCase changeStatus, DeleteRoutineUseCase delete,
                             DuplicateRoutineUseCase duplicate, CloneRoutineUseCase cloneRoutine,
                             AddRoutineWeekUseCase addWeek, UpdateRoutineWeekUseCase updateWeek,
                             DeleteRoutineWeekUseCase deleteWeek, AddRoutineDayUseCase addDay,
                             RenameRoutineDayUseCase renameDay, DeleteRoutineDayUseCase deleteDay,
                             AddRoutineExerciseUseCase addExercise, UpdateRoutineExerciseUseCase updateExercise,
                             RemoveRoutineExerciseUseCase removeExercise, ReorderRoutineExercisesUseCase reorder,
                             GenerateRoutineProposalUseCase generate, RefineRoutineProposalUseCase refine) {
        this.create = create;
        this.get = get;
        this.listMine = listMine;
        this.listCommunity = listCommunity;
        this.update = update;
        this.changeStatus = changeStatus;
        this.delete = delete;
        this.duplicate = duplicate;
        this.cloneRoutine = cloneRoutine;
        this.addWeek = addWeek;
        this.updateWeek = updateWeek;
        this.deleteWeek = deleteWeek;
        this.addDay = addDay;
        this.renameDay = renameDay;
        this.deleteDay = deleteDay;
        this.addExercise = addExercise;
        this.updateExercise = updateExercise;
        this.removeExercise = removeExercise;
        this.reorder = reorder;
        this.generate = generate;
        this.refine = refine;
    }

    // ------------------------------------------------------------------ CRUD

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public RoutineResponse create(@CurrentUserId UUID userId, @Valid @RequestBody CreateRoutineRequest request) {
        return own(create.create(new CreateRoutineUseCase.Command(userId, request.name(), request.description(),
                request.visibility(), request.goal(), request.startDate(), request.structure())), userId);
    }

    @GetMapping
    public PageResponse<RoutineSummaryResponse> listMine(@CurrentUserId UUID userId,
                                                         @RequestParam(required = false) RoutineStatus status,
                                                         @RequestParam(defaultValue = "0") int page,
                                                         @RequestParam(defaultValue = "20") int size) {
        return PageResponse.from(listMine.listMine(userId, status, new PageRequest(page, size)),
                r -> RoutineSummaryResponse.from(r, null));
    }

    @GetMapping("/community")
    public PageResponse<RoutineSummaryResponse> community(@CurrentUserId UUID userId,
                                                          @RequestParam(required = false) String q,
                                                          @RequestParam(required = false) TrainingGoal goal,
                                                          @RequestParam(defaultValue = "0") int page,
                                                          @RequestParam(defaultValue = "20") int size) {
        return PageResponse.from(listCommunity.listCommunity(userId, q, goal, new PageRequest(page, size)),
                (VisibleRoutine v) -> RoutineSummaryResponse.from(v.routine(), v.authorName()));
    }

    @GetMapping("/{routineId}")
    public RoutineResponse get(@CurrentUserId UUID userId, @PathVariable UUID routineId) {
        VisibleRoutine visible = get.get(userId, routineId);
        return RoutineResponse.from(visible.routine(), visible.authorName(), userId);
    }

    @PatchMapping("/{routineId}")
    public RoutineResponse update(@CurrentUserId UUID userId, @PathVariable UUID routineId,
                                  @Valid @RequestBody UpdateRoutineRequest request) {
        return own(update.update(new UpdateRoutineUseCase.Command(userId, routineId, request.name(),
                request.description(), request.visibility(), request.goal(), request.startDate(),
                Boolean.TRUE.equals(request.clearStartDate()))), userId);
    }

    @PutMapping("/{routineId}/status")
    public RoutineResponse changeStatus(@CurrentUserId UUID userId, @PathVariable UUID routineId,
                                        @Valid @RequestBody ChangeRoutineStatusRequest request) {
        return own(changeStatus.changeStatus(userId, routineId, request.status()), userId);
    }

    @DeleteMapping("/{routineId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@CurrentUserId UUID userId, @PathVariable UUID routineId) {
        delete.delete(userId, routineId);
    }

    @PostMapping("/{routineId}/duplicate")
    @ResponseStatus(HttpStatus.CREATED)
    public RoutineResponse duplicate(@CurrentUserId UUID userId, @PathVariable UUID routineId,
                                     @Valid @RequestBody(required = false) DuplicateRoutineRequest request) {
        return own(duplicate.duplicate(userId, routineId, request == null ? null : request.name()), userId);
    }

    /** Copia en la cuenta propia una rutina visible de la comunidad. */
    @PostMapping("/{routineId}/clone")
    @ResponseStatus(HttpStatus.CREATED)
    public RoutineResponse cloneRoutine(@CurrentUserId UUID userId, @PathVariable UUID routineId) {
        return own(cloneRoutine.cloneRoutine(userId, routineId), userId);
    }

    // ------------------------------------------------------------------ estructura

    @PostMapping("/{routineId}/weeks")
    @ResponseStatus(HttpStatus.CREATED)
    public RoutineResponse addWeek(@CurrentUserId UUID userId, @PathVariable UUID routineId,
                                   @Valid @RequestBody(required = false) WeekChangeRequest request) {
        return own(addWeek.addWeek(userId, routineId, request == null ? null : request.name(),
                request == null ? null : request.type()), userId);
    }

    @PatchMapping("/{routineId}/weeks/{weekId}")
    public RoutineResponse updateWeek(@CurrentUserId UUID userId, @PathVariable UUID routineId,
                                      @PathVariable UUID weekId, @Valid @RequestBody WeekChangeRequest request) {
        return own(updateWeek.updateWeek(userId, routineId, weekId, request.name(), request.type()), userId);
    }

    @DeleteMapping("/{routineId}/weeks/{weekId}")
    public RoutineResponse deleteWeek(@CurrentUserId UUID userId, @PathVariable UUID routineId,
                                      @PathVariable UUID weekId) {
        return own(deleteWeek.deleteWeek(userId, routineId, weekId), userId);
    }

    @PostMapping("/{routineId}/weeks/{weekId}/days")
    @ResponseStatus(HttpStatus.CREATED)
    public RoutineResponse addDay(@CurrentUserId UUID userId, @PathVariable UUID routineId, @PathVariable UUID weekId,
                                  @Valid @RequestBody AddDayRequest request) {
        return own(addDay.addDay(userId, routineId, weekId, request.dayNumber(), request.name()), userId);
    }

    @PatchMapping("/{routineId}/days/{dayId}")
    public RoutineResponse renameDay(@CurrentUserId UUID userId, @PathVariable UUID routineId,
                                     @PathVariable UUID dayId, @Valid @RequestBody RenameDayRequest request) {
        return own(renameDay.renameDay(userId, routineId, dayId, request.name()), userId);
    }

    @DeleteMapping("/{routineId}/days/{dayId}")
    public RoutineResponse deleteDay(@CurrentUserId UUID userId, @PathVariable UUID routineId,
                                     @PathVariable UUID dayId) {
        return own(deleteDay.deleteDay(userId, routineId, dayId), userId);
    }

    @PostMapping("/{routineId}/days/{dayId}/exercises")
    @ResponseStatus(HttpStatus.CREATED)
    public RoutineResponse addExercise(@CurrentUserId UUID userId, @PathVariable UUID routineId,
                                       @PathVariable UUID dayId, @Valid @RequestBody PlannedExerciseRequest request) {
        return own(addExercise.addExercise(userId, routineId, dayId, request.exerciseId(), request.parameters()), userId);
    }

    @PutMapping("/{routineId}/days/{dayId}/exercises/order")
    public RoutineResponse reorder(@CurrentUserId UUID userId, @PathVariable UUID routineId, @PathVariable UUID dayId,
                                   @Valid @RequestBody ReorderExercisesRequest request) {
        return own(reorder.reorder(userId, routineId, dayId, request.plannedExerciseIds()), userId);
    }

    @PutMapping("/{routineId}/exercises/{plannedExerciseId}")
    public RoutineResponse updateExercise(@CurrentUserId UUID userId, @PathVariable UUID routineId,
                                          @PathVariable UUID plannedExerciseId,
                                          @Valid @RequestBody ExerciseParametersRequest request) {
        return own(updateExercise.updateExercise(userId, routineId, plannedExerciseId, request.toDomain()), userId);
    }

    @DeleteMapping("/{routineId}/exercises/{plannedExerciseId}")
    public RoutineResponse removeExercise(@CurrentUserId UUID userId, @PathVariable UUID routineId,
                                          @PathVariable UUID plannedExerciseId) {
        return own(removeExercise.removeExercise(userId, routineId, plannedExerciseId), userId);
    }

    // ------------------------------------------------------------------ generación

    /** Genera una propuesta (no se guarda). Para guardarla, enviarla a {@code POST /api/v1/routines}. */
    @PostMapping("/generate")
    public RoutineProposalDto generate(@CurrentUserId UUID userId, @Valid @RequestBody GenerateRoutineRequest request) {
        return RoutineProposalDto.from(generate.generate(new GenerateRoutineProposalUseCase.Command(userId,
                request.durationWeeks(), request.goal(), request.useAi() == null || request.useAi())));
    }

    /** Refina con IA una propuesta (posiblemente editada). */
    @PostMapping("/refine")
    public RoutineProposalDto refine(@CurrentUserId UUID userId, @Valid @RequestBody RoutineProposalDto request) {
        return RoutineProposalDto.from(refine.refine(userId, request.toDomain()));
    }

    private static RoutineResponse own(Routine routine, UUID userId) {
        return RoutineResponse.from(routine, null, userId);
    }
}
