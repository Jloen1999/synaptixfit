package com.synaptixfit.infrastructure.adapter.output.persistence.repository.challenge;

import com.synaptixfit.infrastructure.adapter.output.persistence.entity.challenge.ChallengeProgressEntity;
import java.util.Collection;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

/** Spring Data para {@code progreso_de_reto}. */
public interface ChallengeProgressJpaRepository extends JpaRepository<ChallengeProgressEntity, UUID> {

    List<ChallengeProgressEntity> findByRetoIdOrderByRegistradoEnDesc(UUID retoId);

    /** Progreso manual acumulado de retos sin tareas: filas [reto_id, suma]. */
    @Query("""
            select p.retoId, sum(p.cantidadCompletada) from ChallengeProgressEntity p
            where p.retoId in :ids and p.hitoId is null group by p.retoId
            """)
    List<Object[]> sumManualProgress(@Param("ids") Collection<UUID> ids);
}
