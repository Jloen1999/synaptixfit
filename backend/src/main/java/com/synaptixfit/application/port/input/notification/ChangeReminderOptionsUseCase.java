package com.synaptixfit.application.port.input.notification;

import com.synaptixfit.domain.model.notification.ReminderOptions;
import java.util.UUID;

/**
 * Cambia las opciones de avisos del móvil (interruptores, antelaciones y resumen de la mañana). El cambio es parcial:
 * lo que no viene se queda como estaba.
 */
public interface ChangeReminderOptionsUseCase {

    ReminderOptions change(UUID userId, ReminderOptions.Change change);
}
