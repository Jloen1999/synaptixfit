package com.synaptixfit.infrastructure.adapter.input.rest.run;

import com.synaptixfit.application.port.input.planner.BlockChange;
import com.synaptixfit.application.port.input.run.CreateRunWorkoutUseCase;
import com.synaptixfit.application.port.input.run.DeleteRunWorkoutUseCase;
import com.synaptixfit.application.port.input.run.ListPlannedRunsUseCase;
import com.synaptixfit.application.port.input.run.ListRunWorkoutTemplatesUseCase;
import com.synaptixfit.application.port.input.run.ListRunWorkoutsUseCase;
import com.synaptixfit.application.port.input.run.ScheduleRunWorkoutUseCase;
import com.synaptixfit.application.port.input.run.UpdateRunWorkoutUseCase;
import com.synaptixfit.domain.model.run.PlannedRun;
import com.synaptixfit.domain.model.run.RunStep;
import com.synaptixfit.domain.model.run.RunWorkout;
import com.synaptixfit.domain.model.run.RunWorkoutTemplates;
import com.synaptixfit.infrastructure.adapter.input.rest.support.CurrentUserId;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/**
 * Entrenos de carrera por pasos (ADR 0037): los del usuario, las plantillas, crear, cambiar, borrar, «Poner en el
 * calendario» y los que quedan por hacer.
 */
@Tag(name = "Training - Run workouts")
@RestController
@RequestMapping("/api/v1/training/run-workouts")
public class RunWorkoutController {

    /** Un paso: {@code WARMUP}, {@code RUN}, {@code RECOVER} o {@code COOLDOWN}, por tiempo (s) o distancia (m). */
    public record RunStepDto(@NotNull RunStep.Type type, @NotNull RunStep.Measure measure, int value) {
        RunStep toDomain() {
            return new RunStep(type, measure, value);
        }

        static RunStepDto from(RunStep s) {
            return new RunStepDto(s.type(), s.measure(), s.value());
        }
    }

    /** Pasos que se repiten {@code repeat} veces seguidas. */
    public record RunGroupDto(int repeat, @NotNull List<@Valid RunStepDto> steps) {
        RunWorkout.Group toDomain() {
            return new RunWorkout.Group(repeat, steps.stream().map(RunStepDto::toDomain).toList());
        }

        static RunGroupDto from(RunWorkout.Group g) {
            return new RunGroupDto(g.repeat(), g.steps().stream().map(RunStepDto::from).toList());
        }
    }

    /** Crear o cambiar: nombre (en el idioma de la persona, también si sale de una plantilla) y pasos. */
    public record RunWorkoutRequest(@NotBlank @Size(max = 80) String name, String templateCode,
                                    @NotNull List<@Valid RunGroupDto> groups) {
        List<RunWorkout.Group> domainGroups() {
            return groups.stream().map(RunGroupDto::toDomain).toList();
        }
    }

    /** Entreno de carrera con su duración prevista en segundos. */
    public record RunWorkoutResponse(UUID id, String name, String templateCode, List<RunGroupDto> groups,
                                     int estimatedSeconds) {
        static RunWorkoutResponse from(RunWorkout w) {
            return new RunWorkoutResponse(w.id(), w.name(), w.templateCode(),
                    w.groups().stream().map(RunGroupDto::from).toList(), w.estimatedSeconds());
        }
    }

    /** Plantilla: el cliente pone el nombre y la explicación a partir de {@code code}. */
    public record RunWorkoutTemplateResponse(String code, List<RunGroupDto> groups) {
        static RunWorkoutTemplateResponse from(RunWorkoutTemplates.Template t) {
            return new RunWorkoutTemplateResponse(t.code(), t.groups().stream().map(RunGroupDto::from).toList());
        }
    }

    /** «Poner en el calendario» a esta hora. */
    public record RunScheduleRequest(@NotNull Instant start) {
    }

    /** Evento creado y cuántos eventos se solapan con él (aviso, no error). */
    public record RunScheduleResponse(UUID blockId, Instant start, Instant end, int conflicts) {
        static RunScheduleResponse from(BlockChange c) {
            return new RunScheduleResponse(c.block().id(), c.block().start(), c.block().end(), c.conflicts().size());
        }
    }

    /** Evento con entreno de carrera aún por hacer. */
    public record PlannedRunResponse(UUID blockId, UUID workoutId, String workoutName, Instant start, Instant end) {
        static PlannedRunResponse from(PlannedRun p) {
            return new PlannedRunResponse(p.blockId(), p.workoutId(), p.workoutName(), p.start(), p.end());
        }
    }

    private final ListRunWorkoutsUseCase list;
    private final ListRunWorkoutTemplatesUseCase templates;
    private final CreateRunWorkoutUseCase create;
    private final UpdateRunWorkoutUseCase update;
    private final DeleteRunWorkoutUseCase delete;
    private final ScheduleRunWorkoutUseCase schedule;
    private final ListPlannedRunsUseCase planned;

    public RunWorkoutController(ListRunWorkoutsUseCase list, ListRunWorkoutTemplatesUseCase templates,
                                CreateRunWorkoutUseCase create, UpdateRunWorkoutUseCase update,
                                DeleteRunWorkoutUseCase delete, ScheduleRunWorkoutUseCase schedule,
                                ListPlannedRunsUseCase planned) {
        this.list = list;
        this.templates = templates;
        this.create = create;
        this.update = update;
        this.delete = delete;
        this.schedule = schedule;
        this.planned = planned;
    }

    @GetMapping
    public List<RunWorkoutResponse> list(@CurrentUserId UUID userId) {
        return list.listWorkouts(userId).stream().map(RunWorkoutResponse::from).toList();
    }

    @GetMapping("/templates")
    public List<RunWorkoutTemplateResponse> templates() {
        return templates.listTemplates().stream().map(RunWorkoutTemplateResponse::from).toList();
    }

    @GetMapping("/planned")
    public List<PlannedRunResponse> planned(@CurrentUserId UUID userId) {
        return planned.listPlanned(userId).stream().map(PlannedRunResponse::from).toList();
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public RunWorkoutResponse create(@CurrentUserId UUID userId, @Valid @RequestBody RunWorkoutRequest r) {
        return RunWorkoutResponse.from(create.createWorkout(new CreateRunWorkoutUseCase.Command(userId, r.name(),
                r.templateCode(), r.domainGroups())));
    }

    @PutMapping("/{workoutId}")
    public RunWorkoutResponse update(@CurrentUserId UUID userId, @PathVariable UUID workoutId,
                                     @Valid @RequestBody RunWorkoutRequest r) {
        return RunWorkoutResponse.from(update.updateWorkout(new UpdateRunWorkoutUseCase.Command(userId, workoutId,
                r.name(), r.domainGroups())));
    }

    @DeleteMapping("/{workoutId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@CurrentUserId UUID userId, @PathVariable UUID workoutId) {
        delete.deleteWorkout(userId, workoutId);
    }

    @PostMapping("/{workoutId}/schedule")
    @ResponseStatus(HttpStatus.CREATED)
    public RunScheduleResponse schedule(@CurrentUserId UUID userId, @PathVariable UUID workoutId,
                                        @Valid @RequestBody RunScheduleRequest r) {
        return RunScheduleResponse.from(schedule.scheduleWorkout(userId, workoutId, r.start()));
    }
}
