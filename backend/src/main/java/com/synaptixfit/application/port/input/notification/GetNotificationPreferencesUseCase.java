package com.synaptixfit.application.port.input.notification;

import com.synaptixfit.domain.model.notification.NotificationPreferences;
import java.util.UUID;

/** Preferencias de notificación del usuario (las de por defecto si aún no existen). */
public interface GetNotificationPreferencesUseCase {

    NotificationPreferences getPreferences(UUID userId);
}
