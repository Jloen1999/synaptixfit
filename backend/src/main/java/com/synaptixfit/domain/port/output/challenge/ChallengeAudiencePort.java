package com.synaptixfit.domain.port.output.challenge;

import com.synaptixfit.domain.model.challenge.ChallengeType;
import com.synaptixfit.domain.model.challenge.OwnerAudience;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import java.time.Instant;
import java.util.UUID;

/**
 * Quién puede ver los retos de otros usuarios (amistades aceptadas y autores no silenciados).
 * Lee tablas de los módulos Social y Núcleo.
 */
public interface ChallengeAudiencePort {

    /** Referencia a un reto de la comunidad. */
    record CommunityEntry(UUID challengeId, String ownerName) {
    }

    /**
     * Retos activos de otros usuarios visibles para {@code viewerId}: públicos, o de amigos con
     * amistad aceptada. Excluye autores silenciados (shadowban) o eliminados.
     */
    PageResult<CommunityEntry> findCommunity(UUID viewerId, ChallengeType type, String text, PageRequest page,
                                             Instant now);

    /**
     * Datos de {@code ownerId} vistos por {@code viewerId} (cuenta activa, shadowban, amistad). La
     * decisión la toma {@link com.synaptixfit.domain.model.challenge.Challenge#isVisibleTo}.
     */
    OwnerAudience audienceOf(UUID viewerId, UUID ownerId);
}
