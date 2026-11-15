package com.synaptixfit.infrastructure.adapter.input.rest.badge;

import com.synaptixfit.application.port.input.badge.GetStreakUseCase;
import com.synaptixfit.application.port.input.badge.PauseStreakUseCase;
import com.synaptixfit.application.port.input.badge.ResumeStreakUseCase;
import com.synaptixfit.infrastructure.adapter.input.rest.badge.dto.StreakResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.support.CurrentUserId;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.util.UUID;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/** Racha diaria del usuario y su pausa (ADR 0042). */
@Tag(name = "Streak")
@RestController
@RequestMapping("/api/v1/streak")
public class StreakController {

    private final GetStreakUseCase streak;
    private final PauseStreakUseCase pause;
    private final ResumeStreakUseCase resume;

    public StreakController(GetStreakUseCase streak, PauseStreakUseCase pause, ResumeStreakUseCase resume) {
        this.streak = streak;
        this.pause = pause;
        this.resume = resume;
    }

    /** @param zone zona horaria IANA del dispositivo (p. ej. {@code Europe/Madrid}); define «hoy» y el riesgo. */
    @GetMapping
    public StreakResponse get(@CurrentUserId UUID userId, @RequestParam(required = false) String zone) {
        return StreakResponse.from(streak.getStreak(userId, zone));
    }

    /** Pausa la racha desde hoy, sin cuerpo ni motivo (idempotente si ya está en pausa). */
    @PostMapping("/pause")
    public StreakResponse pause(@CurrentUserId UUID userId, @RequestParam(required = false) String zone) {
        return StreakResponse.from(pause.pause(userId, zone));
    }

    /** Reanuda la racha: la pausa acaba ayer (idempotente si no hay pausa). */
    @DeleteMapping("/pause")
    public StreakResponse resume(@CurrentUserId UUID userId, @RequestParam(required = false) String zone) {
        return StreakResponse.from(resume.resume(userId, zone));
    }
}
