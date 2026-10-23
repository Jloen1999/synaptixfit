package com.synaptixfit.application.port.input.notification;

import com.synaptixfit.domain.model.notification.Notification;
import com.synaptixfit.domain.model.notification.NotificationPriority;
import com.synaptixfit.domain.model.notification.NotificationType;
import java.util.Optional;
import java.util.UUID;

/** Crea una notificación para un usuario respetando sus preferencias (categorías, modo, horas
 * de silencio y límite diario; las críticas siempre se entregan). Contrato interno para que
 * cualquier módulo notifique. */
public interface CreateNotificationUseCase {

    /**
     * @param referenceKey clave estable del hecho avisado (opcional): con ella los avisos automáticos
     *                     comprueban si ya se notificó
     */
    record Command(UUID userId, String title, String description, NotificationPriority priority,
                   NotificationType type, String actionUrl, String actionLabel, String referenceKey) {

        /** Notificación sin clave de referencia (avisos que pueden repetirse). */
        public Command(UUID userId, String title, String description, NotificationPriority priority,
                       NotificationType type, String actionUrl, String actionLabel) {
            this(userId, title, description, priority, type, actionUrl, actionLabel, null);
        }
    }

    /** Devuelve la notificación creada o vacío si las preferencias la han descartado. */
    Optional<Notification> create(Command command);
}
