package com.synaptixfit.infrastructure.adapter.output.persistence.repository.catalog;

import com.synaptixfit.infrastructure.adapter.output.persistence.entity.catalog.BibliographyEntity;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

/** Spring Data para {@code bibliografia_asignatura}. */
public interface BibliographyJpaRepository extends JpaRepository<BibliographyEntity, UUID> {

    List<BibliographyEntity> findByAsignaturaIdOrderByReferenciaAsc(UUID asignaturaId);
}
