package com.synaptixfit.domain.port.output.academic;

import com.synaptixfit.domain.model.academic.NotePhoto;
import com.synaptixfit.domain.model.academic.PageReading;

/**
 * Lee el texto de una foto. Lo usa la lectura de apuntes en papel; la IA del proyecto (DeepSeek) solo entiende
 * texto, así que las imágenes pasan antes por aquí (ADR 0040). Hay dos adaptadores: Tesseract (propio, siempre) y
 * un modelo con visión (Gemini), que solo se usa cuando Tesseract no lee bien y está configurado (ADR 0051).
 */
public interface ImageTextReaderPort {

    /**
     * Texto reconocido en la foto, tal cual (puede venir vacío o con errores de lectura), y su confianza.
     *
     * @throws com.synaptixfit.domain.exception.academic.NoteScanUnsupportedFileException si la imagen no se puede abrir
     * @throws com.synaptixfit.domain.exception.academic.NoteScanUnavailableException si el lector no está disponible
     */
    PageReading read(NotePhoto photo);

    /** ¿Está configurado? El lector con visión no lo está sin su clave; entonces no se le llama. */
    default boolean available() {
        return true;
    }
}
