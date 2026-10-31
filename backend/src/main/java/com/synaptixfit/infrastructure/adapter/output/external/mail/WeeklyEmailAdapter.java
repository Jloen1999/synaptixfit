package com.synaptixfit.infrastructure.adapter.output.external.mail;

import com.synaptixfit.domain.model.notification.WeeklySummary;
import com.synaptixfit.domain.port.output.notification.WeeklyEmailMailerPort;
import com.synaptixfit.infrastructure.config.AppProperties;
import java.time.ZoneId;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

/**
 * Implementa {@link WeeklyEmailMailerPort} con {@link ResendEmailClient} y {@link WeeklyEmailTexts}. Los enlaces
 * de confirmación y de baja van a la API pública ({@code /api/v1/notifications/weekly-email/…}), servida en el
 * mismo dominio que la app.
 */
@Component
public class WeeklyEmailAdapter implements WeeklyEmailMailerPort {

    static final String LINKS = "/api/v1/notifications/weekly-email/";

    private final ResendEmailClient client;
    private final String appUrl;
    private final ZoneId zone;

    public WeeklyEmailAdapter(ResendEmailClient client, AppProperties properties,
                              @Value("${synaptixfit.planner.zone:Europe/Madrid}") String zoneId) {
        this.client = client;
        this.appUrl = properties.mail().appUrl().replaceFirst("/+$", "");
        // Las fechas de «lo que viene» se escriben en la misma zona que el planificador.
        this.zone = ZoneId.of(zoneId);
    }

    @Override
    public void sendConfirmation(String email, String language, String confirmToken) {
        client.send(WeeklyEmailTexts.confirmation(email, language, appUrl + LINKS + "confirm?token=" + confirmToken));
    }

    @Override
    public boolean sendSummary(String email, String language, WeeklySummary summary, String unsubscribeToken,
                               String idempotencyKey) {
        return client.send(WeeklyEmailTexts.summary(email, language, summary, appUrl,
                appUrl + LINKS + "unsubscribe?token=" + unsubscribeToken, zone), idempotencyKey).isPresent();
    }
}
