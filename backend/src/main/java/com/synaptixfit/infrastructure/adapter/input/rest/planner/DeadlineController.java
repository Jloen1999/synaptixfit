package com.synaptixfit.infrastructure.adapter.input.rest.planner;

import com.synaptixfit.application.port.input.planner.CreateDeadlineUseCase;
import com.synaptixfit.application.port.input.planner.DeleteDeadlineUseCase;
import com.synaptixfit.application.port.input.planner.GetDeadlineUseCase;
import com.synaptixfit.application.port.input.planner.GetDeadlinesUseCase;
import com.synaptixfit.application.port.input.planner.SetDeadlineCompletionUseCase;
import com.synaptixfit.application.port.input.planner.UpdateDeadlineUseCase;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.planner.dto.CompletionRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.planner.dto.DeadlineCompletionResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.planner.dto.DeadlineRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.planner.dto.DeadlineResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.planner.dto.DeadlineUpdateRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.support.CurrentUserId;
import com.synaptixfit.infrastructure.adapter.input.rest.support.PageResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.time.Instant;
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

/** Entregas, exámenes y presentaciones. */
@Tag(name = "Planner - Deadlines")
@RestController
@RequestMapping("/api/v1/planner/deadlines")
public class DeadlineController {

    private final CreateDeadlineUseCase create;
    private final UpdateDeadlineUseCase update;
    private final DeleteDeadlineUseCase delete;
    private final GetDeadlineUseCase getOne;
    private final GetDeadlinesUseCase getMany;
    private final SetDeadlineCompletionUseCase setCompletion;

    public DeadlineController(CreateDeadlineUseCase create, UpdateDeadlineUseCase update, DeleteDeadlineUseCase delete,
                              GetDeadlineUseCase getOne, GetDeadlinesUseCase getMany,
                              SetDeadlineCompletionUseCase setCompletion) {
        this.create = create;
        this.update = update;
        this.delete = delete;
        this.getOne = getOne;
        this.getMany = getMany;
        this.setCompletion = setCompletion;
    }

    /**
     * Entregas por fecha límite ascendente. {@code upcoming=true}: solo pendientes desde hoy.
     * {@code from}/{@code to} filtran la fecha límite [from, to).
     */
    @GetMapping
    public PageResponse<DeadlineResponse> list(@CurrentUserId UUID userId,
                                               @RequestParam(required = false) Instant from,
                                               @RequestParam(required = false) Instant to,
                                               @RequestParam(required = false) UUID subjectId,
                                               @RequestParam(defaultValue = "false") boolean upcoming,
                                               @RequestParam(defaultValue = "0") int page,
                                               @RequestParam(defaultValue = "20") int size) {
        return PageResponse.from(getMany.getDeadlines(new GetDeadlinesUseCase.Query(userId, from, to, subjectId,
                upcoming, new PageRequest(page, size))), DeadlineResponse::from);
    }

    @GetMapping("/{deadlineId}")
    public DeadlineResponse get(@CurrentUserId UUID userId, @PathVariable UUID deadlineId) {
        return DeadlineResponse.from(getOne.getDeadline(userId, deadlineId));
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public DeadlineResponse create(@CurrentUserId UUID userId, @Valid @RequestBody DeadlineRequest r) {
        return DeadlineResponse.from(create.createDeadline(new CreateDeadlineUseCase.Command(userId, r.title(),
                r.type(), r.dueAt(), r.difficulty(), r.description(), r.subjectId())));
    }

    @PatchMapping("/{deadlineId}")
    public DeadlineResponse update(@CurrentUserId UUID userId, @PathVariable UUID deadlineId,
                                   @Valid @RequestBody DeadlineUpdateRequest r) {
        return DeadlineResponse.from(update.updateDeadline(new UpdateDeadlineUseCase.Command(userId, deadlineId,
                r.title(), r.type(), r.dueAt(), r.difficulty(), r.description(), r.subjectId(),
                Boolean.TRUE.equals(r.clearSubject()))));
    }

    @DeleteMapping("/{deadlineId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@CurrentUserId UUID userId, @PathVariable UUID deadlineId) {
        delete.deleteDeadline(userId, deadlineId);
    }

    @PutMapping("/{deadlineId}/completion")
    public DeadlineCompletionResponse completion(@CurrentUserId UUID userId, @PathVariable UUID deadlineId,
                                                 @Valid @RequestBody CompletionRequest r) {
        SetDeadlineCompletionUseCase.Result result = setCompletion.setCompletion(userId, deadlineId, r.completed());
        return new DeadlineCompletionResponse(DeadlineResponse.from(result.deadline()), result.xpDelta());
    }
}
