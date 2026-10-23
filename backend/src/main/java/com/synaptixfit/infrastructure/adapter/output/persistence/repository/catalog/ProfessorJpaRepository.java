package com.synaptixfit.infrastructure.adapter.output.persistence.repository.catalog;

import com.synaptixfit.infrastructure.adapter.output.persistence.entity.catalog.ProfessorEntity;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

/** Spring Data para {@code profesores_asignatura}. */
public interface ProfessorJpaRepository extends JpaRepository<ProfessorEntity, UUID> {

    List<ProfessorEntity> findByAsignaturaIdOrderByNombreCompletoAsc(UUID asignaturaId);
}
