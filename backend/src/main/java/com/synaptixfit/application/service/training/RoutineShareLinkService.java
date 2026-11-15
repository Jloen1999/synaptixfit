package com.synaptixfit.application.service.training;

import com.synaptixfit.application.port.input.training.CopySharedRoutineUseCase;
import com.synaptixfit.application.port.input.training.CreateRoutineShareLinkUseCase;
import com.synaptixfit.application.port.input.training.GetRoutineShareLinkStatusUseCase;
import com.synaptixfit.application.port.input.training.PreviewSharedRoutineUseCase;
import com.synaptixfit.application.port.input.training.RevokeRoutineShareLinksUseCase;
import com.synaptixfit.domain.exception.training.RoutineNotFoundException;
import com.synaptixfit.domain.exception.training.RoutineShareLinkLimitException;
import com.synaptixfit.domain.exception.training.RoutineShareLinkNotFoundException;
import com.synaptixfit.domain.model.training.Routine;
import com.synaptixfit.domain.model.training.RoutineShareLink;
import com.synaptixfit.domain.port.output.event.DomainEventPublisherPort;
import com.synaptixfit.domain.port.output.training.RoutineRepositoryPort;
import com.synaptixfit.domain.port.output.training.RoutineShareLinkRepositoryPort;
import java.time.Clock;
import java.time.Instant;
import java.util.Comparator;
import java.util.Optional;
import java.util.UUID;

/**
 * Compartir una rutina por enlace (ADR 0043): el dueño crea, consulta y revoca enlaces
 * ({@link RoutineShareLinkRepositoryPort}); quien abre uno con sesión ve la rutina y la copia como una rutina propia,
 * privada y sin progreso ({@link Routine#copyFor}, guardada con {@link RoutineLifecycle} como cualquier rutina nueva).
 * La copia no guarda de quién viene: el enlace no expone nada del dueño.
 */
public class RoutineShareLinkService implements CreateRoutineShareLinkUseCase, RevokeRoutineShareLinksUseCase,
        GetRoutineShareLinkStatusUseCase, PreviewSharedRoutineUseCase, CopySharedRoutineUseCase {

    /** Un token emitido mide 43 caracteres; algo mucho más largo no se busca. */
    private static final int MAX_TOKEN_LENGTH = 128;

    private final RoutineRepositoryPort routines;
    private final RoutineShareLinkRepositoryPort links;
    private final RoutineLifecycle lifecycle;
    private final Clock clock;

    public RoutineShareLinkService(RoutineRepositoryPort routines, RoutineShareLinkRepositoryPort links,
                                   DomainEventPublisherPort events, Clock clock) {
        this.routines = routines;
        this.links = links;
        this.lifecycle = new RoutineLifecycle(routines, events, clock);
        this.clock = clock;
    }

    @Override
    public Created createShareLink(UUID userId, UUID routineId) {
        Routine routine = owned(userId, routineId);
        links.lockRoutine(routine.id());
        Instant now = clock.instant();
        if (links.findActiveByRoutine(routine.id(), now).size() >= RoutineShareLink.MAX_ACTIVE_PER_ROUTINE) {
            throw new RoutineShareLinkLimitException();
        }
        RoutineShareLink.Issued issued = RoutineShareLink.issue(routine.id(), userId, now);
        links.save(issued.link());
        return new Created(issued.token(), issued.link().expiresAt());
    }

    @Override
    public void revokeShareLinks(UUID userId, UUID routineId) {
        links.revokeAllOfRoutine(owned(userId, routineId).id(), clock.instant());
    }

    @Override
    public Optional<Instant> sharedUntil(UUID userId, UUID routineId) {
        return links.findActiveByRoutine(owned(userId, routineId).id(), clock.instant()).stream()
                .map(RoutineShareLink::expiresAt)
                .max(Comparator.naturalOrder());
    }

    @Override
    public Routine previewSharedRoutine(UUID userId, String token) {
        return shared(userId, token);
    }

    @Override
    public Routine copySharedRoutine(UUID userId, String token) {
        Routine source = shared(userId, token);
        return lifecycle.saveNew(source.copyFor(userId, source.name(), null, clock.instant()));
    }

    /** Rutina del enlace si lo puede abrir {@code userId}; si no, el mismo error para cualquier motivo. */
    private Routine shared(UUID userId, String token) {
        if (token == null || token.isBlank() || token.length() > MAX_TOKEN_LENGTH) {
            throw new RoutineShareLinkNotFoundException();
        }
        Instant now = clock.instant();
        RoutineShareLink link = links.findByTokenHash(RoutineShareLink.hash(token.strip()))
                .orElseThrow(RoutineShareLinkNotFoundException::new);
        return routines.findWithAuthor(link.routineId(), userId)
                .filter(found -> found.routine().isOwnedBy(link.ownerId()) && !found.routine().isDeleted())
                .filter(found -> link.opensFor(userId, found.audience(), now))
                .map(RoutineRepositoryPort.AuthoredRoutine::routine)
                .orElseThrow(RoutineShareLinkNotFoundException::new);
    }

    private Routine owned(UUID userId, UUID routineId) {
        return routines.findById(routineId)
                .filter(r -> r.isOwnedBy(userId) && !r.isDeleted())
                .orElseThrow(() -> new RoutineNotFoundException(routineId));
    }
}
