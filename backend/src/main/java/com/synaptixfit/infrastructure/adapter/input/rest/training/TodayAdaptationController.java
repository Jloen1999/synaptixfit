package com.synaptixfit.infrastructure.adapter.input.rest.training;

import com.synaptixfit.application.port.input.training.GetTodayAdaptationUseCase;
import com.synaptixfit.infrastructure.adapter.input.rest.support.CurrentUserId;
import com.synaptixfit.infrastructure.adapter.input.rest.training.dto.TodayAdaptationResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.util.UUID;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/** Adaptación de hoy para la tarjeta del registro rápido; delega en {@link GetTodayAdaptationUseCase}. */
@Tag(name = "Training wellbeing")
@RestController
@RequestMapping("/api/v1/training")
public class TodayAdaptationController {

    private final GetTodayAdaptationUseCase todayAdaptation;

    public TodayAdaptationController(GetTodayAdaptationUseCase todayAdaptation) {
        this.todayAdaptation = todayAdaptation;
    }

    /** Cómo se adapta hoy el entreno y por qué, sin empezar sesión. */
    @GetMapping("/adaptation/today")
    public TodayAdaptationResponse todayAdaptation(@CurrentUserId UUID userId,
                                                   @RequestParam(required = false) String tz) {
        return TodayAdaptationResponse.from(todayAdaptation.today(userId, tz));
    }
}
