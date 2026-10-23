package com.synaptixfit.application.port.input.badge;

import com.synaptixfit.domain.model.badge.BadgeCategory;
import com.synaptixfit.domain.model.badge.BadgeView;
import java.util.List;
import java.util.UUID;

/** Catálogo de insignias con el estado y el progreso del usuario en cada una. */
public interface GetBadgeCatalogUseCase {

    /**
     * @param category filtro opcional
     * @param zone     zona horaria IANA del usuario; {@code null} = zona por defecto
     */
    List<BadgeView> getBadgeCatalog(UUID userId, BadgeCategory category, String zone);
}
