package com.synaptixfit.domain.model.academic;

import java.time.Instant;
import java.util.Map;

/** URL prefirmada que el cliente usa para subir o descargar directamente del almacenamiento. */
public record SignedUrl(String url, String method, Map<String, String> headers, Instant expiresAt) {

    public SignedUrl {
        headers = headers == null ? Map.of() : Map.copyOf(headers);
    }
}
