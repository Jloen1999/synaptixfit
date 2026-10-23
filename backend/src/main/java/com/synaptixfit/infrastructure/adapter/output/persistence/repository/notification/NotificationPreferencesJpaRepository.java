package com.synaptixfit.infrastructure.adapter.output.persistence.repository.notification;

import com.synaptixfit.infrastructure.adapter.output.persistence.entity.notification.NotificationPreferencesEntity;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

/** Spring Data para {@code preferencias_notificacion}. */
public interface NotificationPreferencesJpaRepository extends JpaRepository<NotificationPreferencesEntity, UUID> {

    Optional<NotificationPreferencesEntity> findByUsuarioId(UUID usuarioId);
}
