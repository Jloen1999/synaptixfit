package com.synaptixfit.infrastructure.adapter.input.rest.training;

import com.synaptixfit.application.port.input.training.CreateRoutineShareLinkUseCase;
import com.synaptixfit.application.port.input.training.GetRoutineShareLinkStatusUseCase;
import com.synaptixfit.application.port.input.training.RevokeRoutineShareLinksUseCase;
import com.synaptixfit.infrastructure.adapter.input.rest.support.CurrentUserId;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.time.Instant;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/**
 * Enlaces del dueño para que otros copien su rutina (ADR 0043): crear ({@link CreateRoutineShareLinkUseCase}), ver
 * hasta cuándo se comparte ({@link GetRoutineShareLinkStatusUseCase}) y dejar de compartir
 * ({@link RevokeRoutineShareLinksUseCase}). La dirección completa la compone la app con el token.
 */
@Tag(name = "Routines")
@RestController
@RequestMapping("/api/v1/routines/{routineId}/share-links")
public class RoutineShareLinkController {

    private final CreateRoutineShareLinkUseCase create;
    private final GetRoutineShareLinkStatusUseCase status;
    private final RevokeRoutineShareLinksUseCase revoke;

    public RoutineShareLinkController(CreateRoutineShareLinkUseCase create, GetRoutineShareLinkStatusUseCase status,
                                      RevokeRoutineShareLinksUseCase revoke) {
        this.create = create;
        this.status = status;
        this.revoke = revoke;
    }

    /** Token del enlace nuevo (solo se ve ahora) y hasta cuándo vale. */
    public record ShareLinkResponse(String token, Instant expiresAt) {
    }

    /** Hasta cuándo vale el último enlace vigente; {@code null} si no se está compartiendo. */
    public record ShareLinkStatusResponse(Instant sharedUntil) {
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public ShareLinkResponse create(@CurrentUserId UUID userId, @PathVariable UUID routineId) {
        CreateRoutineShareLinkUseCase.Created created = create.createShareLink(userId, routineId);
        return new ShareLinkResponse(created.token(), created.expiresAt());
    }

    @GetMapping
    public ShareLinkStatusResponse status(@CurrentUserId UUID userId, @PathVariable UUID routineId) {
        return new ShareLinkStatusResponse(status.sharedUntil(userId, routineId).orElse(null));
    }

    @DeleteMapping
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void revoke(@CurrentUserId UUID userId, @PathVariable UUID routineId) {
        revoke.revokeShareLinks(userId, routineId);
    }
}
