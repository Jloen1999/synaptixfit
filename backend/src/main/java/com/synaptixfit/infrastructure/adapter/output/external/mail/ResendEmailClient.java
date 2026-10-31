package com.synaptixfit.infrastructure.adapter.output.external.mail;

import com.synaptixfit.infrastructure.config.AppProperties;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestClientResponseException;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.json.JsonMapper;

/**
 * Transporte de correo con la API de Resend ({@code POST /emails}). Lo usan los adaptadores de cada correo
 * (p. ej. {@link PasswordResetEmailAdapter}), que componen el texto. No lanza excepciones: devuelve el id del
 * envío o vacío, y los registros nunca incluyen el destinatario ni el contenido (lleva enlaces con token).
 */
@Component
public class ResendEmailClient {

    private static final Logger LOG = LoggerFactory.getLogger(ResendEmailClient.class);
    private static final JsonMapper JSON = JsonMapper.builder().build();

    /** Correo listo para enviar; {@code headers} extra (p. ej. {@code List-Unsubscribe}). */
    public record Message(String to, String subject, String html, String text, Map<String, String> headers) {

        public Message(String to, String subject, String html, String text) {
            this(to, subject, html, text, Map.of());
        }

        @Override
        public String toString() {
            return "Message[" + subject + "]";
        }
    }

    static final long MIN_INTERVAL_MS = 600;

    private final RestClient client;
    private final AppProperties.Mail config;
    private long lastSentAt;

    @Autowired
    public ResendEmailClient(RestClient.Builder builder, AppProperties properties) {
        this(builder.clone().baseUrl("https://api.resend.com").requestFactory(timeouts()).build(), properties.mail());
    }

    /** Para tests: recibe un cliente ya construido (p. ej. contra un servidor simulado). */
    ResendEmailClient(RestClient client, AppProperties.Mail config) {
        this.client = client;
        this.config = config;
    }

    private static SimpleClientHttpRequestFactory timeouts() {
        SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
        factory.setConnectTimeout(10_000);
        factory.setReadTimeout(15_000);
        return factory;
    }

    public Optional<String> send(Message message) {
        return send(message, null);
    }

    /**
     * Envía con un ritmo máximo (Resend admite unas 2 peticiones por segundo) y, si se da, con
     * {@code Idempotency-Key}: repetir el mismo envío no manda otro correo.
     */
    public synchronized Optional<String> send(Message message, String idempotencyKey) {
        if (config == null || config.resendApiKey() == null || config.resendApiKey().isBlank()) {
            LOG.warn("Email «{}» not sent: RESEND_API_KEY is not configured", message.subject());
            return Optional.empty();
        }
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("from", config.from());
        body.put("to", List.of(message.to()));
        body.put("subject", message.subject());
        body.put("html", message.html());
        body.put("text", message.text());
        if (!message.headers().isEmpty()) {
            body.put("headers", message.headers());
        }
        try {
            pace();
            JsonNode response = client.post().uri("/emails")
                    .header("Authorization", "Bearer " + config.resendApiKey())
                    .headers(h -> {
                        if (idempotencyKey != null) {
                            h.add("Idempotency-Key", idempotencyKey);
                        }
                    })
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(body)
                    .retrieve()
                    .body(JsonNode.class);
            String id = response == null ? "" : response.path("id").asString("");
            LOG.info("Email «{}» sent (id {})", message.subject(), id);
            return Optional.of(id);
        } catch (RestClientResponseException e) {
            // Solo el tipo de error de Resend (validation_error, rate_limit_exceeded…): su mensaje puede repetir
            // el remitente o el destinatario.
            LOG.warn("Resend error {} ({})", e.getStatusCode().value(), errorName(e.getResponseBodyAsString()));
        } catch (RestClientException e) {
            LOG.warn("Resend unreachable: {}", e.getMessage());
        }
        return Optional.empty();
    }

    /** Espera lo que falte para dejar {@link #MIN_INTERVAL_MS} entre envíos. */
    private void pace() {
        long wait = lastSentAt + MIN_INTERVAL_MS - System.currentTimeMillis();
        if (wait > 0) {
            try {
                Thread.sleep(wait);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
        }
        lastSentAt = System.currentTimeMillis();
    }

    private static String errorName(String body) {
        try {
            return JSON.readTree(body).path("name").asString("unknown");
        } catch (RuntimeException e) {
            return "unknown";
        }
    }
}
