package com.synaptixfit.application.service.challenge;

import com.synaptixfit.domain.model.challenge.Challenge;
import com.synaptixfit.domain.model.challenge.ChallengeChanges;
import com.synaptixfit.domain.model.challenge.ChallengeStatus;
import com.synaptixfit.domain.port.output.challenge.ChallengeRepositoryPort;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.Collection;
import java.util.UUID;

/**
 * Tras guardar un reto creado o editado (ya recargado con la foto de sus entregas vinculadas y de los
 * bloques de cada tarea): comprueba que los vínculos indicados vencen dentro de su periodo y aplica el
 * estado actual de lo vinculado, que es la fuente de verdad (ADR 0028). Lo comparten el alta, la edición
 * y el reemplazo de tareas.
 */
final class LinkedSourcesSync {

    private final ChallengeRepositoryPort challenges;
    private final ZoneId zone;

    LinkedSourcesSync(ChallengeRepositoryPort challenges, ZoneId zone) {
        this.challenges = challenges;
        this.zone = zone;
    }

    /**
     * @param saved        reto recién guardado y recargado
     * @param linksToCheck ids de las entregas cuyo plazo se comprueba (vínculos nuevos o, si cambian las
     *                     fechas del reto, todos)
     * @param changes      efectos acumulados de la operación; se añaden los de la sincronización
     * @return el reto, guardado otra vez si la sincronización pudo cambiarlo
     */
    Challenge apply(Challenge saved, Collection<UUID> linksToCheck, ChallengeChanges changes, Instant now) {
        saved.requireLinksWithinPeriod(linksToCheck, zone);
        // Un reto vencido queda como estaba; al ampliarlo deja de estarlo y recupera lo ocurrido.
        if (saved.status(now) == ChallengeStatus.EXPIRED || !saved.hasLinkedSources()) {
            return saved;
        }
        changes.merge(saved.syncWithLinks(LocalDate.ofInstant(now, zone)));
        return challenges.save(saved);
    }
}
