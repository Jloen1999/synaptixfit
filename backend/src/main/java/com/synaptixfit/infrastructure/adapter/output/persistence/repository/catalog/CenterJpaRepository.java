package com.synaptixfit.infrastructure.adapter.output.persistence.repository.catalog;

import com.synaptixfit.infrastructure.adapter.output.persistence.entity.catalog.CenterEntity;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

/** Spring Data para {@code centros}. */
public interface CenterJpaRepository extends JpaRepository<CenterEntity, UUID> {

    List<CenterEntity> findByUniversidadIdOrderByNombreAsc(UUID universidadId);
}
