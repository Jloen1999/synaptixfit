package com.synaptixfit.application.port.input.notification;

import java.util.UUID;

/**
 * Aviso de fatiga (categoría FATIGUE_ALERT): el check-in pide adaptar el entrenamiento o el ACWR ha
 * entrado en sobreentrenamiento. Respeta las preferencias y se envía como mucho una vez al día por
 * motivo (idempotente).
 */
public interface NotifyFatigueAlertUseCase {

    /** Motivo del aviso. */
    enum Reason {
        CHECK_IN_ADAPTATION,
        OVERTRAINING
    }

    /** @param acwr ratio agudo/crónico (solo para OVERTRAINING; null en otro caso) */
    record Command(UUID userId, Reason reason, Double acwr) {}

    void notifyFatigue(Command command);
}
