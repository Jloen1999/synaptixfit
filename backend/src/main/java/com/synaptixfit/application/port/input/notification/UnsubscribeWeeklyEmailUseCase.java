package com.synaptixfit.application.port.input.notification;

/** Baja con un clic desde el enlace de cada resumen. Devuelve el idioma de la suscripción (para la página). */
public interface UnsubscribeWeeklyEmailUseCase {

    String unsubscribeWeeklyEmail(String token);
}
