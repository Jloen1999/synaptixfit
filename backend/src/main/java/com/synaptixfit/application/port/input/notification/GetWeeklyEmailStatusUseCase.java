package com.synaptixfit.application.port.input.notification;

import java.util.UUID;

/** Estado de la suscripción al resumen semanal por correo. */
public interface GetWeeklyEmailStatusUseCase {

    WeeklyEmailStatus getWeeklyEmailStatus(UUID userId);
}
