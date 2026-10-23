package com.synaptixfit.infrastructure.adapter.output.persistence.repository.planner;

import com.synaptixfit.infrastructure.adapter.output.persistence.entity.planner.StudyPlanEntity;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

/** Spring Data para {@code planes_estudio}. */
public interface StudyPlanJpaRepository extends JpaRepository<StudyPlanEntity, UUID> {

    /** El más antiguo si hubiera duplicados heredados de la app antigua. */
    Optional<StudyPlanEntity> findFirstByUsuarioIdAndSemanaInicioOrderByCreadoEnAsc(UUID usuarioId, LocalDate semanaInicio);

    Page<StudyPlanEntity> findByUsuarioId(UUID usuarioId, Pageable pageable);

    List<StudyPlanEntity> findByUsuarioIdAndVisibilidadNot(UUID usuarioId, String visibilidad);
}
