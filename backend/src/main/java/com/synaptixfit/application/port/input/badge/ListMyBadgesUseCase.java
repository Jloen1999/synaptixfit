package com.synaptixfit.application.port.input.badge;

import com.synaptixfit.domain.model.badge.BadgeView;
import java.util.List;
import java.util.UUID;

/** Insignias obtenidas por el usuario, de la más reciente a la más antigua. */
public interface ListMyBadgesUseCase {

    List<BadgeView> listMyBadges(UUID userId, boolean includeHidden);
}
