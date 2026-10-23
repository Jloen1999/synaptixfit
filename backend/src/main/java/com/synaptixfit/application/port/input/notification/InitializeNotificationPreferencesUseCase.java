package com.synaptixfit.application.port.input.notification;

import java.util.UUID;

/** Crea las preferencias por defecto de un usuario nuevo. Idempotente. */
public interface InitializeNotificationPreferencesUseCase {

    void initialize(UUID userId);
}
