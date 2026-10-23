package com.synaptixfit.domain.port.output.storage;

import java.time.Instant;
import java.util.Map;

/** URL firmada con el método y cabeceras que el cliente debe usar. */
public record PresignedUrl(String url, String method, Map<String, String> headers, Instant expiresAt) {

    public PresignedUrl {
        headers = Map.copyOf(headers);
    }
}
