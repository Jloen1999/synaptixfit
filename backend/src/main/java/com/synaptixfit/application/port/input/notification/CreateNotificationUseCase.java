package com.synaptixfit.application.port.input.notification;

import com.synaptixfit.domain.model.notification.Notification;
import com.synaptixfit.domain.model.notification.NotificationMessage;
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
     * @param message      código y datos para que el cliente muestre el aviso en su idioma (opcional;
     *                     {@code title} y {@code description} son el respaldo en español)
     */
    record Command(UUID userId, String title, String description, NotificationPriority priority,
                   NotificationType type, String actionUrl, String actionLabel, String referenceKey,
                   NotificationMessage message) {

        public Command(UUID userId, String title, String description, NotificationPriority priority,
                       NotificationType type, String actionUrl, String actionLabel, String referenceKey) {
            this(userId, title, description, priority, type, actionUrl, actionLabel, referenceKey, null);
        }

        /** Notificación sin clave de referencia (avisos que pueden repetirse). */
        public Command(UUID userId, String title, String description, NotificationPriority priority,
                       NotificationType type, String actionUrl, String actionLabel) {
            this(userId, title, description, priority, type, actionUrl, actionLabel, null);
        }
    }

    /** Devuelve la notificación creada o vacío si las preferencias la han descartado. */
    Optional<Notification> create(Command command);
}
