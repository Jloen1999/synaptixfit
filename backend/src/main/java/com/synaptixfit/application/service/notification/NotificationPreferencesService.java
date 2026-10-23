package com.synaptixfit.application.service.notification;

import com.synaptixfit.application.port.input.notification.GetNotificationPreferencesUseCase;
import com.synaptixfit.application.port.input.notification.InitializeNotificationPreferencesUseCase;
import com.synaptixfit.application.port.input.notification.UpdateNotificationPreferencesUseCase;
import com.synaptixfit.domain.model.notification.NotificationPreferences;
import com.synaptixfit.domain.port.output.notification.NotificationPreferencesRepositoryPort;
import java.time.Clock;
import java.time.Instant;
import java.util.UUID;

/** Preferencias de notificación (una fila por usuario, creada al registrarse o en la primera edición). */
public class NotificationPreferencesService implements GetNotificationPreferencesUseCase,
        UpdateNotificationPreferencesUseCase, InitializeNotificationPreferencesUseCase {

    private final NotificationPreferencesRepositoryPort preferences;
    private final Clock clock;

    public NotificationPreferencesService(NotificationPreferencesRepositoryPort preferences, Clock clock) {
        this.preferences = preferences;
        this.clock = clock;
    }

    /** Si aún no existen (usuarios anteriores al módulo), devuelve las de por defecto sin guardarlas. */
    @Override
    public NotificationPreferences getPreferences(UUID userId) {
        return preferences.findByUserId(userId)
                .orElseGet(() -> NotificationPreferences.defaults(userId, clock.instant()));
    }

    @Override
    public NotificationPreferences updatePreferences(UpdateNotificationPreferencesUseCase.Command command) {
        Instant now = clock.instant();
        NotificationPreferences prefs = preferences.findByUserId(command.userId())
                .orElseGet(() -> NotificationPreferences.defaults(command.userId(), now));
        prefs.update(command.activeCategories(), command.quietHoursStart(), command.quietHoursEnd(),
                command.dailyLimit(), command.mode(), now);
        return preferences.save(prefs);
    }

    @Override
    public void initialize(UUID userId) {
        if (preferences.findByUserId(userId).isEmpty()) {
            preferences.save(NotificationPreferences.defaults(userId, clock.instant()));
        }
    }
}
