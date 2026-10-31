package com.synaptixfit.application.port.input.notification;

import java.util.UUID;

/** Desactiva el resumen semanal por correo desde la app. */
public interface DisableWeeklyEmailUseCase {

    void disableWeeklyEmail(UUID userId);
}
