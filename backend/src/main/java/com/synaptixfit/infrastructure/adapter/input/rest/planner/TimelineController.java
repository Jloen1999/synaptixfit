package com.synaptixfit.infrastructure.adapter.input.rest.planner;

import com.synaptixfit.application.port.input.planner.GetTimelineUseCase;
import com.synaptixfit.infrastructure.adapter.input.rest.planner.dto.TimelineItemResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.support.CurrentUserId;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/** Línea de tiempo unificada (inicio y vista de asignatura). */
@Tag(name = "Planner - Timeline")
@RestController
@RequestMapping("/api/v1/planner/timeline")
public class TimelineController {

    private final GetTimelineUseCase getTimeline;

    public TimelineController(GetTimelineUseCase getTimeline) {
        this.getTimeline = getTimeline;
    }

    /** Bloques y entregas de [from, to) (máx. 92 días) ordenados por inicio; filtro opcional por asignatura. */
    @GetMapping
    public List<TimelineItemResponse> timeline(@CurrentUserId UUID userId, @RequestParam Instant from,
                                               @RequestParam Instant to, @RequestParam(required = false) UUID subjectId) {
        return getTimeline.getTimeline(userId, from, to, subjectId).stream().map(TimelineItemResponse::from).toList();
    }
}
