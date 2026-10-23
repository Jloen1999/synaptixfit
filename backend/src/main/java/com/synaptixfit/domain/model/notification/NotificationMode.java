package com.synaptixfit.domain.model.notification;

import java.util.EnumSet;
import java.util.Set;

/**
 * Modo de notificación del usuario.
 * <ul>
 *   <li>{@code NORMAL}: se entregan todas las categorías activas.</li>
 *   <li>{@code EXAMS}: época de exámenes; solo lo académico, conflictos de horario y alertas de fatiga.</li>
 *   <li>{@code REST}: descanso; solo las notificaciones críticas.</li>
 * </ul>
 */
public enum NotificationMode {
    NORMAL(EnumSet.allOf(NotificationType.class)),
    EXAMS(EnumSet.of(NotificationType.ACADEMIC, NotificationType.CONFLICT, NotificationType.FATIGUE_ALERT)),
    REST(EnumSet.noneOf(NotificationType.class));

    private final Set<NotificationType> allowed;

    NotificationMode(Set<NotificationType> allowed) {
        this.allowed = allowed;
    }

    /** ¿Deja pasar este modo una notificación no crítica de ese tipo? */
    public boolean allows(NotificationType type) {
        return allowed.contains(type);
    }
}
