package com.synaptixfit.infrastructure.config;

import java.time.Duration;
import java.util.List;
import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Configuración de la aplicación ({@code synaptixfit.*} en application.yml, alimentada por
 * variables de entorno). Ningún secreto tiene valor por defecto en producción.
 */
@ConfigurationProperties(prefix = "synaptixfit")
public record AppProperties(Jwt jwt, Cors cors, Google google, Ai ai, Storage storage) {

    /** Firma de tokens de acceso (HS256) y caducidades. */
    public record Jwt(String secret, String issuer, Duration accessTokenTtl, Duration refreshTokenTtl) {
    }

    /** Orígenes permitidos para el cliente web. */
    public record Cors(List<String> allowedOrigins) {
    }

    /** IDs de cliente OAuth aceptados como audiencia del ID token de Google. */
    public record Google(List<String> clientIds) {
    }

    /**
     * Proveedor de IA generativa (DeepSeek, API compatible con OpenAI).
     *
     * @param maxTokens límite de tokens de cada respuesta (las rutinas en JSON son largas)
     */
    public record Ai(String apiKey, String model, String baseUrl, Duration timeout, int maxTokens) {
    }

    /** Almacenamiento S3 compatible (Cloudflare R2). */
    public record Storage(String endpoint, String region, String bucket, String accessKey,
                          String secretKey, String publicBaseUrl) {
    }
}
