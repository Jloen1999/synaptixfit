package com.synaptixfit.application.port.input.notification;

/** Confirma la suscripción con el enlace del correo. Devuelve el idioma de la suscripción (para la página). */
public interface ConfirmWeeklyEmailUseCase {

    String confirmWeeklyEmail(String token);
}
