package com.synaptixfit.infrastructure.adapter.output.persistence.repository.catalog;

import com.synaptixfit.infrastructure.adapter.output.persistence.entity.catalog.EvaluationCriteriaEntity;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

/** Spring Data para {@code criterios_evaluacion}. */
public interface EvaluationCriteriaJpaRepository extends JpaRepository<EvaluationCriteriaEntity, UUID> {

    Optional<EvaluationCriteriaEntity> findByAsignaturaId(UUID asignaturaId);
}
