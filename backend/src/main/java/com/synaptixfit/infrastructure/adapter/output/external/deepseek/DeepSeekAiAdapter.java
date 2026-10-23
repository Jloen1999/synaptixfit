package com.synaptixfit.infrastructure.adapter.output.external.deepseek;

import com.synaptixfit.domain.exception.AiQuotaExceededException;
import com.synaptixfit.domain.exception.AiUnavailableException;
import com.synaptixfit.domain.port.output.ai.AiAttachment;
import com.synaptixfit.domain.port.output.ai.GenerativeAiPort;
import com.synaptixfit.infrastructure.config.AppProperties;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientResponseException;
import tools.jackson.databind.JsonNode;

/**
 * Implementa {@link GenerativeAiPort} con la API de DeepSeek ({@code POST /chat/completions},
 * compatible con OpenAI). Es el único sitio que habla con el proveedor de IA: los adaptadores de
 * cada módulo ({@code external/ai/<modulo>/}) solo construyen prompts y leen la respuesta.
 *
 * <p>La clave nunca sale del servidor. Errores del proveedor traducidos a dominio: 402 (sin saldo)
 * y 429 (límite) → {@link AiQuotaExceededException}; el resto → {@link AiUnavailableException}.
 */
@Component
public class DeepSeekAiAdapter implements GenerativeAiPort {

    private static final Logger LOG = LoggerFactory.getLogger(DeepSeekAiAdapter.class);

    /** El modo JSON de DeepSeek exige que el prompt contenga la palabra «json». */
    private static final String JSON_SYSTEM_PROMPT =
            "Responde únicamente con un objeto json válido, sin Markdown ni texto adicional.";

    private final RestClient client;
    private final AppProperties.Ai config;
    private final AttachmentTextExtractor extractor;

    @Autowired
    public DeepSeekAiAdapter(RestClient.Builder builder, AppProperties properties, AttachmentTextExtractor extractor) {
        this(builder.clone().baseUrl(properties.ai().baseUrl()).requestFactory(timeouts(properties.ai())).build(),
                properties.ai(), extractor);
    }

    /** Para tests: recibe un cliente ya construido (p. ej. contra un servidor simulado). */
    DeepSeekAiAdapter(RestClient client, AppProperties.Ai config, AttachmentTextExtractor extractor) {
        this.client = client;
        this.config = config;
        this.extractor = extractor;
    }

    private static SimpleClientHttpRequestFactory timeouts(AppProperties.Ai config) {
        SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
        factory.setConnectTimeout((int) Math.min(config.timeout().toMillis(), 15_000));
        factory.setReadTimeout((int) config.timeout().toMillis());
        return factory;
    }

    @Override
    public String generateText(String prompt, List<AiAttachment> attachments, double temperature) {
        return call(prompt, attachments, temperature, false);
    }

    @Override
    public String generateJson(String prompt, List<AiAttachment> attachments, double temperature) {
        return stripCodeFences(call(prompt, attachments, temperature, true));
    }

    private String call(String prompt, List<AiAttachment> attachments, double temperature, boolean json) {
        if (config.apiKey() == null || config.apiKey().isBlank()) {
            throw new AiUnavailableException("DeepSeek API key is not configured");
        }
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("model", config.model());
        body.put("messages", messages(withAttachments(prompt, attachments), json));
        body.put("temperature", temperature);
        body.put("max_tokens", config.maxTokens());
        body.put("stream", false);
        if (json) {
            body.put("response_format", Map.of("type", "json_object"));
        }
        try {
            JsonNode response = client.post()
                    .uri("/chat/completions")
                    .header("Authorization", "Bearer " + config.apiKey())
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(body)
                    .retrieve()
                    .body(JsonNode.class);
            return extractText(response);
        } catch (RestClientResponseException e) {
            int status = e.getStatusCode().value();
            if (status == 402 || status == 429) {
                throw new AiQuotaExceededException();
            }
            // El cuerpo de error de DeepSeek no contiene la clave; se registra para diagnosticar.
            LOG.warn("DeepSeek error {}: {}", status, e.getResponseBodyAsString());
            throw new AiUnavailableException("DeepSeek returned " + status);
        } catch (ResourceAccessException e) {
            throw new AiUnavailableException("DeepSeek unreachable: " + e.getMessage());
        } catch (RestClientException e) {
            // Respuesta que no se puede leer (JSON mal formado, tipo de contenido inesperado…).
            throw new AiUnavailableException("Unreadable DeepSeek response: " + e.getMessage());
        }
    }

    /** Los adjuntos se convierten a texto y se añaden al final del prompt, numerados. */
    private String withAttachments(String prompt, List<AiAttachment> attachments) {
        if (attachments == null || attachments.isEmpty()) {
            return prompt;
        }
        StringBuilder full = new StringBuilder(prompt);
        for (int i = 0; i < attachments.size(); i++) {
            full.append("\n\n=== DOCUMENTO ").append(i + 1).append(" ===\n")
                    .append(extractor.toText(attachments.get(i)));
        }
        return full.toString();
    }

    private static List<Map<String, String>> messages(String prompt, boolean json) {
        List<Map<String, String>> messages = new ArrayList<>();
        if (json) {
            messages.add(Map.of("role", "system", "content", JSON_SYSTEM_PROMPT));
        }
        messages.add(Map.of("role", "user", "content", prompt));
        return messages;
    }

    private static String extractText(JsonNode response) {
        if (response == null) {
            throw new AiUnavailableException("Empty DeepSeek response");
        }
        JsonNode choice = response.path("choices").path(0);
        String text = choice.path("message").path("content").asString("");
        if ("length".equals(choice.path("finish_reason").asString(""))) {
            // Se agotó max_tokens: la respuesta está cortada (un JSON incompleto no sirve).
            throw new AiUnavailableException("DeepSeek response was truncated (max_tokens)");
        }
        if (text.isBlank()) {
            throw new AiUnavailableException("DeepSeek returned no text");
        }
        return text.strip();
    }

    /** Por si el modelo envuelve el JSON en ```json … ``` aunque se pida modo JSON. */
    static String stripCodeFences(String text) {
        String t = text.strip();
        if (t.startsWith("```")) {
            int firstNewline = t.indexOf('\n');
            int lastFence = t.lastIndexOf("```");
            if (firstNewline > 0 && lastFence > firstNewline) {
                return t.substring(firstNewline + 1, lastFence).strip();
            }
        }
        return t;
    }
}
