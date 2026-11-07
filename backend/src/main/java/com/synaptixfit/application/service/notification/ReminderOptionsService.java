package com.synaptixfit.application.service.notification;

import com.synaptixfit.application.port.input.notification.ChangeReminderOptionsUseCase;
import com.synaptixfit.application.port.input.notification.GetReminderOptionsUseCase;
import com.synaptixfit.domain.model.notification.ReminderOptions;
import com.synaptixfit.domain.port.output.notification.ReminderOptionsRepositoryPort;
import java.time.Clock;
import java.util.Objects;
import java.util.UUID;

/**
 * Opciones de avisos del móvil; sin nada guardado, {@link ReminderOptions#DEFAULTS}. Un cambio se aplica sobre lo
 * guardado ({@link ReminderOptions#with}), que valida las opciones cerradas, y se guarda con su puerto.
 */
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
    public ReminderOptions change(UUID userId, ReminderOptions.Change change) {
        ReminderOptions changed = get(userId).with(Objects.requireNonNull(change, "change"));
        options.save(userId, changed, clock.instant());
        return changed;
    }
}
