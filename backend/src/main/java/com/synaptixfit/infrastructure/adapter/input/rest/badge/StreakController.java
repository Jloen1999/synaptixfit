package com.synaptixfit.infrastructure.adapter.input.rest.badge;

import com.synaptixfit.application.port.input.badge.GetStreakUseCase;
import com.synaptixfit.infrastructure.adapter.input.rest.badge.dto.StreakResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.support.CurrentUserId;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.util.UUID;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/** Racha diaria del usuario. */
@Tag(name = "Streak")
@RestController
@RequestMapping("/api/v1/streak")
public class StreakController {

    private final GetStreakUseCase streak;

    public StreakController(GetStreakUseCase streak) {
        this.streak = streak;
    }

    /** @param zone zona horaria IANA del dispositivo (p. ej. {@code Europe/Madrid}); define «hoy» y el riesgo. */
    @GetMapping
    public StreakResponse get(@CurrentUserId UUID userId, @RequestParam(required = false) String zone) {
        return StreakResponse.from(streak.getStreak(userId, zone));
    }
}
