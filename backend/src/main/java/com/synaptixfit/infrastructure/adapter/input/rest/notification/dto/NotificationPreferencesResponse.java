package com.synaptixfit.infrastructure.adapter.input.rest.notification.dto;

import com.synaptixfit.domain.model.notification.NotificationMode;
import com.synaptixfit.domain.model.notification.NotificationPreferences;
import com.synaptixfit.domain.model.notification.NotificationType;
import java.time.Instant;
import java.time.LocalTime;
import java.util.List;

/** Preferencias de notificación. Horas de silencio en hora local (HH:mm:ss), ambas nulas si no hay. */
public record NotificationPreferencesResponse(List<NotificationType> activeCategories, LocalTime quietHoursStart,
                                              LocalTime quietHoursEnd, int dailyLimit, NotificationMode mode,
                                              Instant updatedAt) {

    public static NotificationPreferencesResponse from(NotificationPreferences p) {
        return new NotificationPreferencesResponse(p.activeCategories().stream().sorted().toList(),
                p.quietHoursStart(), p.quietHoursEnd(), p.dailyLimit(), p.mode(), p.updatedAt());
    }
}
