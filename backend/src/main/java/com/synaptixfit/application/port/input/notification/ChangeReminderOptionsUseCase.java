package com.synaptixfit.application.port.input.notification;

import com.synaptixfit.domain.model.notification.ReminderOptions;
import java.util.UUID;

/** Enciende o apaga los avisos opcionales del móvil. */
public interface ChangeReminderOptionsUseCase {

    ReminderOptions change(UUID userId, ReminderOptions options);
}
