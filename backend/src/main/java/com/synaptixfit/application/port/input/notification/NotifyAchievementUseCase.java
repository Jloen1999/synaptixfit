package com.synaptixfit.application.port.input.notification;

import java.util.UUID;

/**
 * Notificación de un logro (categoría MILESTONE): reto completado, insignia desbloqueada, subida
 * de nivel o ciclo de rutina terminado. Respeta las preferencias del usuario y no repite el mismo aviso (idempotente).
 */
public interface NotifyAchievementUseCase {

    /** Tipo de logro. */
    enum Kind {
        CHALLENGE_COMPLETED,
        BADGE_EARNED,
        LEVEL_UP,
        ROUTINE_COMPLETED
    }

    /**
     * @param name        título del reto, nombre de la insignia o de la rutina, o nivel alcanzado
     * @param referenceId reto, insignia o rutina (null en la subida de nivel)
     */
    record Command(UUID userId, Kind kind, String name, UUID referenceId) {}

    void notifyAchievement(Command command);
}
