package com.synaptixfit.application.port.input.notification;

import java.util.UUID;

/**
 * Notificación de un logro (categoría MILESTONE): reto completado, insignia desbloqueada o subida
 * de nivel. Respeta las preferencias del usuario y no repite el mismo aviso (idempotente).
 */
public interface NotifyAchievementUseCase {

    /** Tipo de logro. */
    enum Kind {
        CHALLENGE_COMPLETED,
        BADGE_EARNED,
        LEVEL_UP
    }

    /**
     * @param name        título del reto, nombre de la insignia o nivel alcanzado
     * @param referenceId reto o insignia (null en la subida de nivel)
     */
    record Command(UUID userId, Kind kind, String name, UUID referenceId) {}

    void notifyAchievement(Command command);
}
