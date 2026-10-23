package com.synaptixfit.infrastructure.adapter.output.persistence.repository.catalog;

import com.synaptixfit.infrastructure.adapter.output.persistence.entity.catalog.UserDegreeEntity;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

/** Spring Data para {@code usuario_carreras}. */
public interface UserDegreeJpaRepository extends JpaRepository<UserDegreeEntity, UUID> {

    List<UserDegreeEntity> findByUsuarioIdOrderByCreadoEnAsc(UUID usuarioId);

    boolean existsByUsuarioIdAndCarreraId(UUID usuarioId, UUID carreraId);

    @Modifying
    @Query("delete from UserDegreeEntity e where e.usuarioId = :usuarioId and e.carreraId = :carreraId")
    int deleteLink(@Param("usuarioId") UUID usuarioId, @Param("carreraId") UUID carreraId);
}
