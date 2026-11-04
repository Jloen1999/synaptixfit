package com.synaptixfit.domain.port.output.academic;

import com.synaptixfit.domain.model.academic.NotePhoto;

/**
 * Lee el texto de una foto (OCR). Lo usa la lectura de apuntes en papel; la IA del proyecto
 * (DeepSeek) solo entiende texto, así que las imágenes pasan antes por aquí (ADR 0040).
 */
public interface ImageTextReaderPort {

    /**
     * Texto reconocido en la foto, tal cual (puede venir vacío o con errores de lectura).
     *
     * @throws com.synaptixfit.domain.exception.academic.NoteScanUnsupportedFileException si la imagen no se puede abrir
     * @throws com.synaptixfit.domain.exception.academic.NoteScanUnavailableException si el lector no está disponible
     */
    String read(NotePhoto photo);
}
