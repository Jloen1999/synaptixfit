package com.synaptixfit.infrastructure.adapter.output.external.mail;

import com.synaptixfit.domain.port.output.auth.PasswordResetMailerPort;
import com.synaptixfit.infrastructure.config.AppProperties;
import com.synaptixfit.infrastructure.i18n.RequestLanguage;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.DisposableBean;
import org.springframework.stereotype.Component;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

/**
 * Implementa {@link PasswordResetMailerPort} con {@link ResendEmailClient}. El enlace lleva el token en el
 * fragmento ({@code /#/reset-password?token=…}): el navegador no lo envía al servidor, así que no queda en los
 * registros de nginx ni de Cloudflare.
 *
 * <p>El envío sale en segundo plano y solo si la transacción se confirma: la respuesta tarda lo mismo exista o no
 * la cuenta (no se puede averiguar qué correos están registrados midiendo el tiempo) y no se manda un enlace que
 * no llegó a guardarse.
 */
@Component
public class PasswordResetEmailAdapter implements PasswordResetMailerPort, DisposableBean {

    private static final Logger LOG = LoggerFactory.getLogger(PasswordResetEmailAdapter.class);

    private final ResendEmailClient client;
    private final String appUrl;
    private final Clock clock;
    private final ExecutorService executor = Executors.newVirtualThreadPerTaskExecutor();

    public PasswordResetEmailAdapter(ResendEmailClient client, AppProperties properties, Clock clock) {
        this.client = client;
        this.appUrl = properties.mail().appUrl().replaceFirst("/+$", "");
        this.clock = clock;
        // Fallos de configuración que no se notan en la respuesta (siempre 202): se avisan al arrancar.
        String key = properties.mail().resendApiKey();
        if (key == null || key.isBlank()) {
            LOG.warn("RESEND_API_KEY is not set: password reset emails will not be sent");
        } else if (!appUrl.startsWith("https://")) {
            LOG.warn("APP_PUBLIC_URL is {}: emails will link to a non-HTTPS address (fine only in local)", appUrl);
        }
    }

    @Override
    public void sendPasswordReset(String email, String rawToken, Instant expiresAt) {
        // El idioma se lee ahora: en el hilo del envío ya no hay petición.
        String language = RequestLanguage.code();
        // Hacia arriba: el reloj ya avanzó unos milisegundos y 30 minutos no deben leerse «29».
        long minutes = Math.max(1, (Duration.between(clock.instant(), expiresAt).toSeconds() + 59) / 60);
        String link = appUrl + "/#/reset-password?token=" + rawToken;
        ResendEmailClient.Message message = PasswordResetEmail.compose(email, link, minutes, language);
        Runnable send = () -> client.send(message);
        if (TransactionSynchronizationManager.isSynchronizationActive()) {
            TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
                @Override
                public void afterCommit() {
                    executor.execute(send);
                }
            });
        } else {
            executor.execute(send);
        }
    }

    @Override
    public void destroy() {
        executor.close();
    }
}
