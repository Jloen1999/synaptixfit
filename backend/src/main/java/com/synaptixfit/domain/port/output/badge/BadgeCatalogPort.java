package com.synaptixfit.domain.port.output.badge;

import com.synaptixfit.domain.model.badge.Badge;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/** Catálogo de insignias ({@code insignias}). */
public interface BadgeCatalogPort {

    /** Todas las insignias ordenadas por {@code orden}. */
    List<Badge> findAll();

    Optional<Badge> findById(UUID id);
}
