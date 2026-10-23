package com.synaptixfit.infrastructure.adapter.output.persistence.repository.badge;

import com.synaptixfit.infrastructure.adapter.output.persistence.entity.badge.UserBadgeEntity;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

/** Spring Data para {@code usuario_insignias}. */
public interface UserBadgeJpaRepository extends JpaRepository<UserBadgeEntity, UUID> {

    List<UserBadgeEntity> findByUsuarioId(UUID usuarioId);

    Optional<UserBadgeEntity> findByUsuarioIdAndInsigniaId(UUID usuarioId, UUID insigniaId);
}
