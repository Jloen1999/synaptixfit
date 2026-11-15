package com.synaptixfit.infrastructure.adapter.output.external.gemini;

import com.synaptixfit.domain.exception.academic.NoteScanUnavailableException;
import com.synaptixfit.domain.exception.academic.NoteScanUnsupportedFileException;
import com.synaptixfit.domain.model.academic.NotePhoto;
import com.synaptixfit.domain.model.academic.PageReading;
import com.synaptixfit.domain.model.shared.ImageHeader;
import com.synaptixfit.domain.port.output.academic.ImageTextReaderPort;
import com.synaptixfit.infrastructure.adapter.output.external.image.ImagePixels;
import java.time.Duration;
import java.util.Base64;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.Semaphore;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestClientResponseException;
import tools.jackson.databind.JsonNode;

/**
 * Segundo adaptador de {@link ImageTextReaderPort}: transcribe la foto con un modelo con visión de Google
 * (Gemini, {@code POST /v1beta/models/{modelo}:generateContent} con la imagen en línea). Solo se usa cuando
 * Tesseract lee con poca confianza y {@code GEMINI_API_KEY} está configurada (ADR 0051); sin clave queda
 * desactivado ({@link #available()} falso) y no se le llama.
 *
 * <p>La foto sale a Google: lo dice la política de privacidad. Se manda ya girada, sin metadatos (ni EXIF ni
 * GPS) y reducida a {@code GEMINI_MAX_SIDE} px. Sin reintentos: si falla, vale lo que leyó Tesseract. Los
 * errores se traducen a {@link NoteScanUnavailableException} y el caso de uso los absorbe.
 */
@Component
public class GeminiImageTextReader implements ImageTextReaderPort {

    private static final Logger LOG = LoggerFactory.getLogger(GeminiImageTextReader.class);

    /** Transcribir, no interpretar: la misma regla que se le da a la IA que ordena. */
    static final String PROMPT = """
            Transcribe literalmente el texto de la imagen, sin añadir ni corregir nada. Respeta el idioma original, \
            los saltos de línea y las fórmulas tal como aparecen. No describas la imagen ni añadas comentarios. \
            Si no hay texto legible, responde vacío.""";

    /** Configuración del lector; sin {@code apiKey} el lector está desactivado. */
    public record Settings(String apiKey, String model, Duration timeout, int maxSide, String thinkingLevel,
                           int maxConcurrent) {

        @Override
        public String toString() {
            return "Settings[model=" + model + ", timeout=" + timeout + ", maxSide=" + maxSide + ", apiKey=***]";
        }
    }

    private final RestClient client;
    private final Settings settings;
    private final Semaphore slots;

    @Autowired
    public GeminiImageTextReader(RestClient.Builder builder,
                                 @Value("${synaptixfit.vision.base-url}") String baseUrl,
                                 @Value("${synaptixfit.vision.api-key:}") String apiKey,
                                 @Value("${synaptixfit.vision.model}") String model,
                                 @Value("${synaptixfit.vision.timeout:30s}") Duration timeout,
                                 @Value("${synaptixfit.vision.max-side:2048}") int maxSide,
                                 @Value("${synaptixfit.vision.thinking-level:}") String thinkingLevel,
                                 @Value("${synaptixfit.vision.max-concurrent:2}") int maxConcurrent) {
        this(builder.clone().baseUrl(baseUrl).requestFactory(timeouts(timeout)).build(),
                new Settings(apiKey, model, timeout, maxSide, thinkingLevel, maxConcurrent));
    }

    /** Para tests: recibe un cliente ya construido (p. ej. contra un servidor simulado). */
    GeminiImageTextReader(RestClient client, Settings settings) {
        this.client = client;
        this.settings = settings;
        this.slots = new Semaphore(Math.max(1, settings.maxConcurrent()));
    }

    private static SimpleClientHttpRequestFactory timeouts(Duration timeout) {
        SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
        factory.setConnectTimeout((int) Math.min(timeout.toMillis(), 10_000));
        factory.setReadTimeout((int) timeout.toMillis());
        return factory;
    }

    @Override
    public boolean available() {
        return settings.apiKey() != null && !settings.apiKey().isBlank();
    }

    @Override
    public PageReading read(NotePhoto photo) {
        if (!available()) {
            throw new NoteScanUnavailableException("Vision reader is not configured");
        }
        // Sin cola: si ya hay lecturas en marcha, se sigue con lo que leyó Tesseract.
        if (!slots.tryAcquire()) {
            throw new NoteScanUnavailableException("Vision reader is busy");
        }
        try {
            return PageReading.unscored(call(prepare(photo.content())));
        } finally {
            slots.release();
        }
    }

    /** JPEG derecho, reducido y sin metadatos. */
    byte[] prepare(byte[] content) {
        int orientation = ImageHeader.read(content).map(ImageHeader::orientation).orElse(ImageHeader.UPRIGHT);
        return ImagePixels.decode(content, settings.maxSide())
                .map(image -> ImagePixels.jpeg(ImagePixels.orient(image, orientation), 0.85f))
                .orElseThrow(NoteScanUnsupportedFileException::new);
    }

    private String call(byte[] jpeg) {
        Map<String, Object> generation = new LinkedHashMap<>();
        generation.put("temperature", 0);
        generation.put("maxOutputTokens", 8192);
        if (settings.thinkingLevel() != null && !settings.thinkingLevel().isBlank()) {
            // Copiar texto no necesita razonar: menos espera y menos coste.
            generation.put("thinkingConfig", Map.of("thinkingLevel", settings.thinkingLevel()));
        }
        Map<String, Object> body = Map.of(
                "contents", List.of(Map.of("role", "user", "parts", List.of(
                        Map.of("inlineData", Map.of("mimeType", "image/jpeg",
                                "data", Base64.getEncoder().encodeToString(jpeg))),
                        Map.of("text", PROMPT)))),
                "generationConfig", generation);
        try {
            JsonNode response = client.post()
                    .uri("/v1beta/models/{model}:generateContent", settings.model())
                    .header("x-goog-api-key", settings.apiKey())
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(body)
                    .retrieve()
                    .body(JsonNode.class);
            return extractText(response);
        } catch (RestClientResponseException e) {
            // Solo el estado: el cuerpo de error no lleva la clave, pero tampoco hace falta guardarlo.
            LOG.warn("Gemini vision returned {}", e.getStatusCode().value());
            throw new NoteScanUnavailableException("Vision reader returned " + e.getStatusCode().value());
        } catch (RestClientException e) {
            LOG.warn("Gemini vision unreachable or unreadable: {}", e.getClass().getSimpleName());
            throw new NoteScanUnavailableException("Vision reader failed");
        }
    }

    /** Une los trozos de texto de la primera respuesta (sin los de razonamiento). Bloqueada: error. */
    static String extractText(JsonNode response) {
        if (response == null) {
            throw new NoteScanUnavailableException("Empty vision response");
        }
        if (!response.path("promptFeedback").path("blockReason").asString("").isEmpty()) {
            throw new NoteScanUnavailableException("Vision request was blocked");
        }
        JsonNode candidate = response.path("candidates").path(0);
        String finish = candidate.path("finishReason").asString("");
        if (!finish.isEmpty() && !"STOP".equals(finish) && !"MAX_TOKENS".equals(finish)) {
            throw new NoteScanUnavailableException("Vision response ended with " + finish);
        }
        StringBuilder text = new StringBuilder();
        for (JsonNode part : candidate.path("content").path("parts")) {
            if (!part.path("thought").asBoolean(false)) {
                text.append(part.path("text").asString(""));
            }
        }
        return text.toString().strip();
    }
}
