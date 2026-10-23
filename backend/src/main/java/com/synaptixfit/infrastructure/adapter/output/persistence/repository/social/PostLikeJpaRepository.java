package com.synaptixfit.infrastructure.adapter.output.persistence.repository.social;

import com.synaptixfit.infrastructure.adapter.output.persistence.entity.social.PostLikeEntity;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

/** Spring Data para {@code interacciones_sociales}. */
public interface PostLikeJpaRepository extends JpaRepository<PostLikeEntity, UUID> {

    boolean existsByActividadIdAndUsuarioId(UUID actividadId, UUID usuarioId);

    long countByActividadId(UUID actividadId);

    @Modifying(flushAutomatically = true, clearAutomatically = true)
    @Query("delete from PostLikeEntity l where l.actividadId = :postId and l.usuarioId = :userId")
    int deleteLike(@Param("postId") UUID postId, @Param("userId") UUID userId);
}
