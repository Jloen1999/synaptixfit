package com.synaptixfit.domain.port.output.academic;

/**
 * Ordena con IA el texto leído de unas fotos de apuntes: corrige errores evidentes de lectura y lo
 * estructura en Markdown sin añadir contenido. Lo usa la lectura de apuntes en papel.
 */
public interface NoteTidierPort {

    /** Título propuesto (puede ser nulo) y texto ordenado en Markdown. */
    record TidiedNote(String title, String markdown) {
    }

    /**
     * @throws com.synaptixfit.domain.exception.AiUnavailableException si la IA falla o responde mal
     * @throws com.synaptixfit.domain.exception.AiQuotaExceededException si se agotó la cuota
     */
    TidiedNote tidy(String recognizedText);
}
