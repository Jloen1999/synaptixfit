package com.synaptixfit.infrastructure.adapter.output.persistence.repository.catalog;

import com.synaptixfit.infrastructure.adapter.output.persistence.entity.catalog.PrerequisiteEntity;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

/** Spring Data para {@code prerrequisitos_asignatura}. */
public interface PrerequisiteJpaRepository extends JpaRepository<PrerequisiteEntity, UUID> {

    List<PrerequisiteEntity> findByAsignaturaIdOrderByNombreAsignaturaAsc(UUID asignaturaId);
}
