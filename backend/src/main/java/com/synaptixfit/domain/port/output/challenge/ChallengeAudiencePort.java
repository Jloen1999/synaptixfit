package com.synaptixfit.domain.port.output.challenge;

import com.synaptixfit.domain.model.challenge.ChallengeType;
import com.synaptixfit.domain.model.shared.AuthorAudience;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import java.time.Instant;
import java.util.UUID;

/**
 * Quién puede ver los retos de otros usuarios (regla de {@code EffectiveVisibility}).
 * Lee tablas de los módulos Social y Núcleo.
 */
public interface ChallengeAudiencePort {

    /** Referencia a un reto de la comunidad. */
    record CommunityEntry(UUID challengeId, String ownerName) {
    }

    /**
     * Retos activos de otros usuarios visibles para {@code viewerId} según {@code EffectiveVisibility}
     * (visibilidad del reto y del perfil, bloqueos, autores silenciados o eliminados).
     */
    PageResult<CommunityEntry> findCommunity(UUID viewerId, ChallengeType type, String text, PageRequest page,
                                             Instant now);

    /**
     * Datos de {@code ownerId} vistos por {@code viewerId} (cuenta, privacidad, amistad, bloqueo). La
     * decisión la toma {@link com.synaptixfit.domain.model.challenge.Challenge#isVisibleTo}.
     */
    AuthorAudience audienceOf(UUID viewerId, UUID ownerId);
}
