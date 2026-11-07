package com.synaptixfit.infrastructure.adapter.input.rest.challenge;

import com.synaptixfit.application.port.input.challenge.ListRoutineDayLinkTargetsUseCase;
import com.synaptixfit.infrastructure.adapter.input.rest.challenge.dto.RoutineDayTargetResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.support.CurrentUserId;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.util.List;
import java.util.UUID;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Días de la rutina en curso a los que se puede vincular una tarea de reto ({@link ListRoutineDayLinkTargetsUseCase}).
 * La tarea vinculada se completa sola al entrenar ese día (ADR 0032).
 */
@Tag(name = "Challenges")
@RestController
@RequestMapping("/api/v1/challenges/routine-day-targets")
public class ChallengeLinkTargetController {

    private final ListRoutineDayLinkTargetsUseCase targets;

    public ChallengeLinkTargetController(ListRoutineDayLinkTargetsUseCase targets) {
        this.targets = targets;
    }

    @GetMapping
    public List<RoutineDayTargetResponse> list(@CurrentUserId UUID userId) {
        return targets.routineDayTargets(userId).stream().map(RoutineDayTargetResponse::from).toList();
    }
}
