package com.synaptixfit.infrastructure.adapter.output.persistence.repository.training;

import com.synaptixfit.infrastructure.adapter.output.persistence.entity.training.TrainingSessionEntity;
import java.time.Instant;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

/** Spring Data para {@code sesiones_registradas}. */
public interface TrainingSessionJpaRepository extends JpaRepository<TrainingSessionEntity, UUID> {

    Page<TrainingSessionEntity> findByUsuarioIdOrderByCreadoEnDesc(UUID usuarioId, Pageable pageable);

    Page<TrainingSessionEntity> findByUsuarioIdAndCompletadaEnIsNotNullOrderByCompletadaEnDesc(UUID usuarioId, Pageable pageable);

    Page<TrainingSessionEntity> findByUsuarioIdAndCompletadaEnIsNullOrderByCreadoEnDesc(UUID usuarioId, Pageable pageable);

    Optional<TrainingSessionEntity> findFirstByUsuarioIdAndDiaIdAndCompletadaEnIsNullOrderByCreadoEnDesc(UUID usuarioId, UUID diaId);

    boolean existsByDiaIdAndCompletadaEnIsNotNullAndIdNot(UUID diaId, UUID id);

    Optional<TrainingSessionEntity> findFirstByUsuarioIdAndCompletadaEnIsNotNullOrderByCompletadaEnDesc(UUID usuarioId);

    long countByUsuarioIdAndCompletadaEnGreaterThanEqualAndCompletadaEnLessThan(UUID usuarioId, Instant from, Instant to);

    long countByUsuarioIdAndCompletadaEnGreaterThanEqualAndCompletadaEnLessThanAndXpOtorgadoGreaterThan(
            UUID usuarioId, Instant from, Instant to, int xp);
}
