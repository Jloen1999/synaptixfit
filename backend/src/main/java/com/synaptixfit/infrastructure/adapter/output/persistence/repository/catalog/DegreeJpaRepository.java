package com.synaptixfit.infrastructure.adapter.output.persistence.repository.catalog;

import com.synaptixfit.infrastructure.adapter.output.persistence.entity.catalog.DegreeEntity;
import java.util.Collection;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

/** Spring Data para {@code carreras}. */
public interface DegreeJpaRepository extends JpaRepository<DegreeEntity, UUID> {

    List<DegreeEntity> findByCentroIdInOrderByNombreAsc(Collection<UUID> centroIds);

    List<DegreeEntity> findByNombreIgnoreCase(String nombre);
}
