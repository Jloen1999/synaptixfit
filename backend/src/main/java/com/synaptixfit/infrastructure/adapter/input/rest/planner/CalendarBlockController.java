package com.synaptixfit.infrastructure.adapter.input.rest.planner;

import com.synaptixfit.application.port.input.planner.BlockDetailsInput;
import com.synaptixfit.application.port.input.planner.CreateCalendarBlockUseCase;
import com.synaptixfit.application.port.input.planner.DeleteCalendarBlockUseCase;
import com.synaptixfit.application.port.input.planner.DistributeRoutineUseCase;
import com.synaptixfit.application.port.input.planner.GetCalendarBlockUseCase;
import com.synaptixfit.application.port.input.planner.GetCalendarBlocksUseCase;
import com.synaptixfit.application.port.input.planner.GetScheduleConflictsUseCase;
import com.synaptixfit.application.port.input.planner.RescheduleCalendarBlockUseCase;
import com.synaptixfit.application.port.input.planner.SetBlockCompletionUseCase;
import com.synaptixfit.application.port.input.planner.UpdateCalendarBlockUseCase;
import com.synaptixfit.infrastructure.adapter.input.rest.planner.dto.BlockChangeResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.planner.dto.BlockCompletionResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.planner.dto.BlockDetailsRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.planner.dto.CalendarBlockRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.planner.dto.CalendarBlockResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.planner.dto.CompletionRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.planner.dto.ConflictResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.planner.dto.RescheduleRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.planner.dto.RoutineDistributionRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.support.CurrentUserId;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import org.springframework.format.annotation.DateTimeFormat;
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

/** Bloques del calendario (lienzo semanal). */
@Tag(name = "Planner - Blocks")
@RestController
@RequestMapping("/api/v1/planner/blocks")
public class CalendarBlockController {

    private final GetCalendarBlocksUseCase getBlocks;
    private final GetCalendarBlockUseCase getBlock;
    private final CreateCalendarBlockUseCase createBlock;
    private final UpdateCalendarBlockUseCase updateBlock;
    private final RescheduleCalendarBlockUseCase reschedule;
    private final DeleteCalendarBlockUseCase deleteBlock;
    private final SetBlockCompletionUseCase setCompletion;
    private final DistributeRoutineUseCase distributeRoutine;
    private final GetScheduleConflictsUseCase getConflicts;

    public CalendarBlockController(GetCalendarBlocksUseCase getBlocks, GetCalendarBlockUseCase getBlock,
                                   CreateCalendarBlockUseCase createBlock, UpdateCalendarBlockUseCase updateBlock,
                                   RescheduleCalendarBlockUseCase reschedule, DeleteCalendarBlockUseCase deleteBlock,
                                   SetBlockCompletionUseCase setCompletion, DistributeRoutineUseCase distributeRoutine,
                                   GetScheduleConflictsUseCase getConflicts) {
        this.getBlocks = getBlocks;
        this.getBlock = getBlock;
        this.createBlock = createBlock;
        this.updateBlock = updateBlock;
        this.reschedule = reschedule;
        this.deleteBlock = deleteBlock;
        this.setCompletion = setCompletion;
        this.distributeRoutine = distributeRoutine;
        this.getConflicts = getConflicts;
    }

    /** Bloques que se solapan con [from, to) (máx. 92 días), opcionalmente de una asignatura. */
    @GetMapping
    public List<CalendarBlockResponse> list(@CurrentUserId UUID userId, @RequestParam Instant from,
                                            @RequestParam Instant to, @RequestParam(required = false) UUID subjectId) {
        return getBlocks.getBlocks(userId, from, to, subjectId).stream().map(CalendarBlockResponse::from).toList();
    }

    @GetMapping("/{blockId}")
    public CalendarBlockResponse get(@CurrentUserId UUID userId, @PathVariable UUID blockId) {
        return CalendarBlockResponse.from(getBlock.getBlock(userId, blockId));
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public BlockChangeResponse create(@CurrentUserId UUID userId, @Valid @RequestBody CalendarBlockRequest r) {
        BlockDetailsInput details = new BlockDetailsInput(r.type(), r.subjectId(), r.topics(), r.location(),
                r.priority(), Boolean.TRUE.equals(r.privateBlock()), r.classKind(), r.routineId(), r.routineWeekId(),
                r.routineDayId(), r.challengeId(), r.milestoneId(), r.deadlineId(), r.deadlineTitle(),
                r.deadlineDifficulty());
        return BlockChangeResponse.from(createBlock.createBlock(new CreateCalendarBlockUseCase.Command(
                userId, r.start(), r.end(), Boolean.TRUE.equals(r.fixed()), details,
                r.repeatWeeks() == null ? 0 : r.repeatWeeks())));
    }

    @PutMapping("/{blockId}")
    public CalendarBlockResponse update(@CurrentUserId UUID userId, @PathVariable UUID blockId,
                                        @Valid @RequestBody BlockDetailsRequest r) {
        BlockDetailsInput details = new BlockDetailsInput(r.type(), r.subjectId(), r.topics(), r.location(),
                r.priority(), Boolean.TRUE.equals(r.privateBlock()), r.classKind(), r.routineId(), r.routineWeekId(),
                r.routineDayId(), r.challengeId(), r.milestoneId(), r.deadlineId(), null, null);
        return CalendarBlockResponse.from(updateBlock.updateBlock(
                new UpdateCalendarBlockUseCase.Command(userId, blockId, details)));
    }

    @PatchMapping("/{blockId}/schedule")
    public BlockChangeResponse reschedule(@CurrentUserId UUID userId, @PathVariable UUID blockId,
                                          @Valid @RequestBody RescheduleRequest r) {
        return BlockChangeResponse.from(reschedule.reschedule(
                new RescheduleCalendarBlockUseCase.Command(userId, blockId, r.start(), r.end())));
    }

    @DeleteMapping("/{blockId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@CurrentUserId UUID userId, @PathVariable UUID blockId) {
        deleteBlock.deleteBlock(userId, blockId);
    }

    @PutMapping("/{blockId}/completion")
    public BlockCompletionResponse completion(@CurrentUserId UUID userId, @PathVariable UUID blockId,
                                              @Valid @RequestBody CompletionRequest r) {
        SetBlockCompletionUseCase.Result result = setCompletion.setCompletion(userId, blockId, r.completed());
        return new BlockCompletionResponse(CalendarBlockResponse.from(result.block()), result.xpDelta());
    }

    @PostMapping("/routine-distribution")
    @ResponseStatus(HttpStatus.CREATED)
    public List<CalendarBlockResponse> distribute(@CurrentUserId UUID userId,
                                                  @Valid @RequestBody RoutineDistributionRequest r) {
        return distributeRoutine.distribute(new DistributeRoutineUseCase.Command(userId, r.routineId(), r.weekdays(),
                        r.startDate(), r.preferredStart(), r.durationMinutes() == null ? 60 : r.durationMinutes()))
                .stream().map(CalendarBlockResponse::from).toList();
    }

    /** Pares de bloques solapados de la semana que contiene {@code weekStart}. */
    @GetMapping("/conflicts")
    public List<ConflictResponse> conflicts(@CurrentUserId UUID userId,
                                            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate weekStart) {
        return getConflicts.getConflicts(userId, weekStart).stream()
                .map(p -> new ConflictResponse(CalendarBlockResponse.from(p.first()), CalendarBlockResponse.from(p.second())))
                .toList();
    }
}
