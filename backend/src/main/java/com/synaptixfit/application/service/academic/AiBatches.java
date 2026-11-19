package com.synaptixfit.application.service.academic;

import com.synaptixfit.domain.exception.AiUnavailableException;
import java.util.function.Supplier;

/**
 * Llamada a la IA de una tanda con un reintento (ADR 0058). Solo se reintenta {@link AiUnavailableException}
 * (respuesta cortada, JSON roto o fallo del proveedor): con la cuota agotada reintentar no sirve.
 */
final class AiBatches {

    /** Intentos por tanda: uno más arregla casi siempre un JSON cortado; más alargaría la espera. */
    static final int ATTEMPTS = 2;

    private AiBatches() {
    }

    static <T> T withRetry(Supplier<T> call) {
        AiUnavailableException last = null;
        for (int attempt = 0; attempt < ATTEMPTS; attempt++) {
            try {
                return call.get();
            } catch (AiUnavailableException e) {
                last = e;
            }
        }
        throw last;
    }
}
