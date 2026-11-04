package com.synaptixfit.application.port.input.notification;

import com.synaptixfit.domain.model.notification.ReminderOptions;
import java.util.UUID;

/** Qué avisos opcionales del móvil tiene encendidos el usuario (racha, registro diario, clases). */
public interface GetReminderOptionsUseCase {

    ReminderOptions get(UUID userId);
}
