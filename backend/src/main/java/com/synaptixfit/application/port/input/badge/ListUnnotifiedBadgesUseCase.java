package com.synaptixfit.application.port.input.badge;

import com.synaptixfit.domain.model.badge.BadgeView;
import java.util.List;
import java.util.UUID;

/** Insignias obtenidas que aún no se han mostrado al usuario (cola de avisos). */
public interface ListUnnotifiedBadgesUseCase {

    List<BadgeView> listUnnotifiedBadges(UUID userId);
}
