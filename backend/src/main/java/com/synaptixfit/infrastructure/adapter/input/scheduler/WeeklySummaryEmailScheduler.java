package com.synaptixfit.infrastructure.adapter.input.scheduler;

import com.synaptixfit.application.port.input.notification.SendWeeklySummariesUseCase;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

/**
 * Adaptador de entrada programado: cada domingo por la tarde envía el resumen semanal por correo (ADR 0022).
 * Repetirlo no duplica correos (cada suscripción recuerda la última semana enviada). La hora se cambia con
 * {@code synaptixfit.mail.weekly-cron}; {@code -} lo desactiva (tests).
 */
@Component
public class WeeklySummaryEmailScheduler {

    private static final Logger LOG = LoggerFactory.getLogger(WeeklySummaryEmailScheduler.class);

    private final SendWeeklySummariesUseCase sendWeeklySummaries;

    public WeeklySummaryEmailScheduler(SendWeeklySummariesUseCase sendWeeklySummaries) {
        this.sendWeeklySummaries = sendWeeklySummaries;
    }

    @Scheduled(cron = "${synaptixfit.mail.weekly-cron:0 0 19-23 * * SUN}",
            zone = "${synaptixfit.planner.zone:Europe/Madrid}")
    public void sendWeeklySummaries() {
        int sent = sendWeeklySummaries.sendWeeklySummaries();
        LOG.info("Weekly summary emails sent: {} (failed: {})", sent, sendWeeklySummaries.lastFailures());
    }
}
