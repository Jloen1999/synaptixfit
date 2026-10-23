package com.synaptixfit.infrastructure.adapter.output.persistence.repository.profile;

import com.synaptixfit.infrastructure.adapter.output.persistence.entity.profile.WellnessProfileEntity;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

/** Spring Data para {@code perfil_bienestar_usuario}. */
public interface WellnessProfileJpaRepository extends JpaRepository<WellnessProfileEntity, UUID> {

    Optional<WellnessProfileEntity> findByUsuarioId(UUID usuarioId);
}
