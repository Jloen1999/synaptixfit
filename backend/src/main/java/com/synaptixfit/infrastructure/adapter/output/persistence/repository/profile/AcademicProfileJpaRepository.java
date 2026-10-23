package com.synaptixfit.infrastructure.adapter.output.persistence.repository.profile;

import com.synaptixfit.infrastructure.adapter.output.persistence.entity.profile.AcademicProfileEntity;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

/** Spring Data para {@code perfil_academico_usuario}. */
public interface AcademicProfileJpaRepository extends JpaRepository<AcademicProfileEntity, UUID> {

    Optional<AcademicProfileEntity> findByUsuarioId(UUID usuarioId);
}
