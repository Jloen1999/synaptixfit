package com.synaptixfit.domain.port.output.notification;

import com.synaptixfit.domain.model.notification.ReminderOptions;
import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

/** Avisos opcionales del móvil que el usuario ha encendido o apagado (sin fila: los de por defecto). */
public interface ReminderOptionsRepositoryPort {

    Optional<ReminderOptions> find(UUID userId);

    void save(UUID userId, ReminderOptions options, Instant now);
}
