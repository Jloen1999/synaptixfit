package com.synaptixfit.domain.model.social;

import com.synaptixfit.domain.model.badge.BadgeRarity;
import java.time.Instant;
import java.util.Comparator;
import java.util.UUID;

/**
 * Insignia que un usuario ha ganado y deja ver en su perfil público ({@link PublicProfile}). Solo
 * se ofrecen las marcadas como visibles por su dueño.
 */
public record PublicBadge(UUID id, String name, String description, String icon, BadgeRarity rarity,
                          Instant earnedAt) {

    /**
     * Orden de escaparate: primero las más difíciles de conseguir (son las que dicen más de la
     * persona) y, a igual rareza, las más recientes.
     */
    public static final Comparator<PublicBadge> SHOWCASE_ORDER = Comparator
            .comparing(PublicBadge::rarity, Comparator.reverseOrder())
            .thenComparing(PublicBadge::earnedAt, Comparator.nullsLast(Comparator.reverseOrder()));
}
