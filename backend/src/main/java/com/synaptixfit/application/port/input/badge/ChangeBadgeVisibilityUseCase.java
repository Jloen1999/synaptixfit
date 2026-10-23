package com.synaptixfit.application.port.input.badge;

import com.synaptixfit.domain.model.badge.BadgeView;
import java.util.UUID;

/** Muestra u oculta una insignia obtenida en el perfil. */
public interface ChangeBadgeVisibilityUseCase {

    BadgeView changeBadgeVisibility(UUID userId, UUID badgeId, boolean visible);
}
