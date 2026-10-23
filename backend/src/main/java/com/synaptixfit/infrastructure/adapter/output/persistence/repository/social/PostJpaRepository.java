package com.synaptixfit.infrastructure.adapter.output.persistence.repository.social;

import com.synaptixfit.infrastructure.adapter.output.persistence.entity.social.PostEntity;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

/** Spring Data para {@code actividades_sociales}. */
public interface PostJpaRepository extends JpaRepository<PostEntity, UUID> {

    boolean existsByUsuarioIdAndTipoAndMetadata(UUID usuarioId, String tipo, String metadata);
}
