package com.synaptixfit.infrastructure.adapter.output.persistence.repository.training;

import com.synaptixfit.infrastructure.adapter.output.persistence.entity.training.RecommendationEntity;
import java.util.UUID;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

/** Spring Data para {@code recomendaciones_pendientes}. */
public interface RecommendationJpaRepository extends JpaRepository<RecommendationEntity, UUID> {

    Page<RecommendationEntity> findByUsuarioIdOrderByCreadoEnDesc(UUID usuarioId, Pageable pageable);

    Page<RecommendationEntity> findByUsuarioIdAndAplicadaOrderByCreadoEnDesc(UUID usuarioId, boolean aplicada, Pageable pageable);
}
