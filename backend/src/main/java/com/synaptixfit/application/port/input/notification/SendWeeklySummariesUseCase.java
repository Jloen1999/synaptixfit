package com.synaptixfit.application.port.input.notification;

/** Envía el resumen de la semana a cada suscripción activa que aún no lo tenga. Devuelve cuántos salieron. */
public interface SendWeeklySummariesUseCase {

    int sendWeeklySummaries();

    /** Personas del último envío con las que algo falló (se reintentan en la siguiente ejecución). */
    int lastFailures();
}
