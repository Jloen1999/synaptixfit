package com.synaptixfit.infrastructure.adapter.input.event.notification;

import com.synaptixfit.application.port.input.notification.InitializeNotificationPreferencesUseCase;
import com.synaptixfit.domain.event.user.UserRegistered;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;

/** Al registrarse un usuario, crea sus preferencias de notificación por defecto (idempotente). */
@Component
public class NotificationPreferencesUserRegisteredListener {

    private final InitializeNotificationPreferencesUseCase initializePreferences;

    public NotificationPreferencesUserRegisteredListener(
            InitializeNotificationPreferencesUseCase initializePreferences) {
        this.initializePreferences = initializePreferences;
    }

    @EventListener
    public void on(UserRegistered event) {
        initializePreferences.initialize(event.userId());
    }
}
