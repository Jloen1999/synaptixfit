package com.synaptixfit.infrastructure.adapter.input.rest.planner;

import com.synaptixfit.application.port.input.planner.LogPastActivityUseCase;
import com.synaptixfit.application.port.input.planner.SetBlockCompletionUseCase;
import com.synaptixfit.infrastructure.adapter.input.rest.planner.dto.BlockCompletionResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.planner.dto.CalendarBlockResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.support.CurrentUserId;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.time.Instant;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/** Apuntar una actividad física que ya pasó (bloque de deporte completado con su esfuerzo). */
@Tag(name = "Planner - Blocks")
@RestController
@RequestMapping("/api/v1/planner/past-activities")
public class PastActivityController {

    /** Actividad pasada: inicio, duración (30-300 min), qué fue y esfuerzo (1-10). */
    public record PastActivityRequest(@NotNull Instant start, @Min(30) @Max(300) int minutes,
                                      @Size(max = 200) String title, @Min(1) @Max(10) int effort) {
    }

    private final LogPastActivityUseCase logPastActivity;

    public PastActivityController(LogPastActivityUseCase logPastActivity) {
        this.logPastActivity = logPastActivity;
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public BlockCompletionResponse log(@CurrentUserId UUID userId, @Valid @RequestBody PastActivityRequest r) {
        SetBlockCompletionUseCase.Result result = logPastActivity.logPastActivity(
                new LogPastActivityUseCase.Command(userId, r.start(), r.minutes(), r.title(), r.effort()));
        return new BlockCompletionResponse(CalendarBlockResponse.from(result.block()), result.xpDelta());
    }
}
