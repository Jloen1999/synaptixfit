package com.synaptixfit.application.port.input.notification;

import com.synaptixfit.domain.model.notification.NotificationMode;
import com.synaptixfit.domain.model.notification.NotificationPreferences;
import com.synaptixfit.domain.model.notification.NotificationType;
import java.time.LocalTime;
import java.util.Set;
import java.util.UUID;

/** Sustituye las preferencias de notificación del usuario. */
public interface UpdateNotificationPreferencesUseCase {

    /** Horas de silencio: ambas nulas (sin silencio) o ambas informadas. */
    record Command(UUID userId, Set<NotificationType> activeCategories, LocalTime quietHoursStart,
                   LocalTime quietHoursEnd, int dailyLimit, NotificationMode mode) {}

    NotificationPreferences updatePreferences(Command command);
}
