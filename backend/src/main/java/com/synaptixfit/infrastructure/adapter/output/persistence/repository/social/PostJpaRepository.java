package com.synaptixfit.infrastructure.adapter.output.persistence.repository.social;

import com.synaptixfit.infrastructure.adapter.output.persistence.entity.social.PostEntity;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;

/** Spring Data para {@code actividades_sociales}. */
public interface PostJpaRepository extends JpaRepository<PostEntity, UUID> {

    boolean existsByUsuarioIdAndTipoAndMetadata(UUID usuarioId, String tipo, String metadata);

    @Modifying(flushAutomatically = true, clearAutomatically = true)
    @Query("delete from PostEntity p where p.usuarioId = :usuarioId and p.tipo = :tipo and p.metadata = :metadata")
    void deleteByAuthorTypeAndMetadata(UUID usuarioId, String tipo, String metadata);
}
