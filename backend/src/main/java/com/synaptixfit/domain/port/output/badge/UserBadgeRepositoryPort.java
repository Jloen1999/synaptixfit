package com.synaptixfit.domain.port.output.badge;

import com.synaptixfit.domain.model.badge.UserBadge;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/** Insignias obtenidas por los usuarios ({@code usuario_insignias}). */
public interface UserBadgeRepositoryPort {

    List<UserBadge> findByUser(UUID userId);

    Optional<UserBadge> find(UUID userId, UUID badgeId);

    /**
     * Otorga la insignia si el usuario no la tenía (restricción única usuario + insignia).
     * Devuelve true si se ha insertado.
     */
    boolean awardIfAbsent(UserBadge badge);

    UserBadge save(UserBadge badge);
}
