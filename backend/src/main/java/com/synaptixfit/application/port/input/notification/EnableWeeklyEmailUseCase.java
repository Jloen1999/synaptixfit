package com.synaptixfit.application.port.input.notification;

import java.util.UUID;

/**
 * Activa el resumen semanal por correo en {@code language}. Si el correo no está verificado (cuenta sin Google),
 * queda pendiente y se manda un correo para confirmarlo; si ya estaba activa, solo cambia el idioma.
 */
public interface EnableWeeklyEmailUseCase {

    WeeklyEmailStatus enableWeeklyEmail(UUID userId, String language);
}
