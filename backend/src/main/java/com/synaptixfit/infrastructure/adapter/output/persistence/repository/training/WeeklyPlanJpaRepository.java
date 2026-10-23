package com.synaptixfit.infrastructure.adapter.output.persistence.repository.training;

import com.synaptixfit.infrastructure.adapter.output.persistence.entity.training.WeeklyPlanEntity;
import java.time.LocalDate;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

/** Spring Data para {@code plan_entrenamiento_semanal}. */
public interface WeeklyPlanJpaRepository extends JpaRepository<WeeklyPlanEntity, UUID> {

    Optional<WeeklyPlanEntity> findByUsuarioIdAndSemanaInicio(UUID usuarioId, LocalDate semanaInicio);

    Page<WeeklyPlanEntity> findByUsuarioIdOrderBySemanaInicioDesc(UUID usuarioId, Pageable pageable);
}
