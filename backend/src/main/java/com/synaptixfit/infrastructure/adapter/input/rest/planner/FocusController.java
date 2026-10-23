package com.synaptixfit.infrastructure.adapter.input.rest.planner;

import com.synaptixfit.application.port.input.planner.GetFocusPlanUseCase;
import com.synaptixfit.application.port.input.planner.GetFocusStatsUseCase;
import com.synaptixfit.application.port.input.planner.RecordFocusSessionUseCase;
import com.synaptixfit.infrastructure.adapter.input.rest.planner.dto.FocusPlanResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.planner.dto.FocusSessionRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.planner.dto.FocusSessionResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.planner.dto.FocusStatsResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.support.CurrentUserId;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.time.LocalDate;
import java.util.UUID;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/** Pomodoro: registro de fases terminadas y estadísticas (el temporizador vive en el cliente). */
@Tag(name = "Planner - Focus")
@RestController
@RequestMapping("/api/v1/planner/focus-sessions")
public class FocusController {

    private final RecordFocusSessionUseCase record;
    private final GetFocusStatsUseCase stats;
    private final GetFocusPlanUseCase plan;

    public FocusController(RecordFocusSessionUseCase record, GetFocusStatsUseCase stats, GetFocusPlanUseCase plan) {
        this.record = record;
        this.stats = stats;
        this.plan = plan;
    }

    /** Duraciones recomendadas para hoy (las mismas que muestra Inicio). */
    @GetMapping("/plan")
    public FocusPlanResponse plan(@CurrentUserId UUID userId, @RequestParam(required = false) String tz) {
        return FocusPlanResponse.from(plan.getFocusPlan(userId, tz));
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public FocusSessionResponse record(@CurrentUserId UUID userId, @Valid @RequestBody FocusSessionRequest r) {
        return FocusSessionResponse.from(record.record(new RecordFocusSessionUseCase.Command(userId, r.phase(),
                r.durationMinutes(), r.cycles() == null ? 1 : r.cycles(), !Boolean.FALSE.equals(r.completed()),
                r.date(), r.blockId(), r.subjectId())));
    }

    /** Estadísticas del día ({@code date}, hoy por defecto) y de su semana. */
    @GetMapping("/stats")
    public FocusStatsResponse stats(@CurrentUserId UUID userId,
                                    @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        return FocusStatsResponse.from(stats.getStats(userId, date));
    }
}
