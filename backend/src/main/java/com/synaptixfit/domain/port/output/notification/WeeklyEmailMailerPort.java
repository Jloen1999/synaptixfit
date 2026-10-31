package com.synaptixfit.domain.port.output.notification;

import com.synaptixfit.domain.model.notification.WeeklySummary;

/**
 * Correos del resumen semanal: la confirmación de la suscripción y el resumen. El adaptador compone el texto en
 * {@code language} y los enlaces; el resumen lleva siempre el enlace para darse de baja con un clic.
 */
public interface WeeklyEmailMailerPort {

    void sendConfirmation(String email, String language, String confirmToken);

    /**
     * @param idempotencyKey clave del envío (usuario y semana): si se repite, el proveedor no lo duplica
     * @return true si el proveedor aceptó el correo (si no, se reintenta en la siguiente ejecución)
     */
    boolean sendSummary(String email, String language, WeeklySummary summary, String unsubscribeToken,
                        String idempotencyKey);
}
