package com.synaptixfit.domain.port.output.user;

import com.synaptixfit.domain.model.notification.ReminderPlanner;
import java.util.Optional;
import java.util.UUID;

/** Fecha de nacimiento y nombre de una cuenta para felicitarla en el plan de avisos (ADR 0036). */
public interface BirthdayPort {

    /** Vacío si la cuenta no tiene fecha de nacimiento (es opcional). */
    Optional<ReminderPlanner.Birthday> birthdayOf(UUID userId);
}
