package com.synaptixfit.infrastructure.adapter.output.persistence.repository.social;

import com.synaptixfit.infrastructure.adapter.output.persistence.entity.social.FriendshipEntity;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

/** Spring Data para {@code amistades}. */
public interface FriendshipJpaRepository extends JpaRepository<FriendshipEntity, UUID> {

    /** Relaciones entre dos usuarios en ambos sentidos, la más reciente primero. */
    @Query("""
            select f from FriendshipEntity f
            where (f.solicitanteId = :a and f.receptorId = :b) or (f.solicitanteId = :b and f.receptorId = :a)
            order by f.actualizadoEn desc
            """)
    List<FriendshipEntity> findBetween(@Param("a") UUID a, @Param("b") UUID b);
}
