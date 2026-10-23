package com.synaptixfit.domain.port.output.notification;

import com.synaptixfit.domain.model.notification.NotificationPreferences;
import java.util.Optional;
import java.util.UUID;

/** Persistencia de preferencias de notificación (una por usuario). */
public interface NotificationPreferencesRepositoryPort {

    Optional<NotificationPreferences> findByUserId(UUID userId);

    NotificationPreferences save(NotificationPreferences preferences);
}
