package com.synaptixfit.application.service.notification;

import com.synaptixfit.application.port.input.notification.ChangeReminderOptionsUseCase;
import com.synaptixfit.application.port.input.notification.GetReminderOptionsUseCase;
import com.synaptixfit.domain.model.notification.ReminderOptions;
import com.synaptixfit.domain.port.output.notification.ReminderOptionsRepositoryPort;
import java.time.Clock;
import java.util.Objects;
import java.util.UUID;

/** Avisos opcionales del móvil; sin nada guardado, {@link ReminderOptions#DEFAULTS}. Guarda con su puerto. */
public class ReminderOptionsService implements GetReminderOptionsUseCase, ChangeReminderOptionsUseCase {

    private final ReminderOptionsRepositoryPort options;
    private final Clock clock;

    public ReminderOptionsService(ReminderOptionsRepositoryPort options, Clock clock) {
        this.options = options;
        this.clock = clock;
    }

    @Override
    public ReminderOptions get(UUID userId) {
        return options.find(userId).orElse(ReminderOptions.DEFAULTS);
    }

    @Override
    public ReminderOptions change(UUID userId, ReminderOptions changed) {
        options.save(userId, Objects.requireNonNull(changed, "options"), clock.instant());
        return changed;
    }
}
