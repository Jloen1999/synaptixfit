package com.synaptixfit.application.port.input.notification;

import java.util.UUID;

/** Marca todas las notificaciones propias como leídas. */
public interface MarkAllNotificationsReadUseCase {

    /** Devuelve cuántas notificaciones han cambiado. */
    int markAllRead(UUID userId);
}
