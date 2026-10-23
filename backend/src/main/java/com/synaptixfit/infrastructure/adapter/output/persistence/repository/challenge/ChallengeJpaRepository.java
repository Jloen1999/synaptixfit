package com.synaptixfit.infrastructure.adapter.output.persistence.repository.challenge;

import com.synaptixfit.infrastructure.adapter.output.persistence.entity.challenge.ChallengeEntity;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

/** Spring Data para {@code retos}. */
public interface ChallengeJpaRepository extends JpaRepository<ChallengeEntity, UUID> {

    List<ChallengeEntity> findByUsuarioIdAndEstaCompletadoFalseAndFechaFinGreaterThanEqualOrderByFechaFinAsc(
            UUID usuarioId, Instant now);

    List<ChallengeEntity> findByUsuarioIdAndVisibilidadNot(UUID usuarioId, String visibilidad);

    List<ChallengeEntity> findByUsuarioIdAndTipoAndSesionesObjetivoIsNotNull(UUID usuarioId, String tipo);

    @Query("""
            select c from ChallengeEntity c
            where c.usuarioId = :ownerId
              and (c.entidadVinculadaId = :entityId
                   or c.id in (select m.retoId from MilestoneEntity m where m.entidadVinculadaId = :entityId))
            """)
    List<ChallengeEntity> findLinkedTo(@Param("ownerId") UUID ownerId, @Param("entityId") UUID entityId);
}
