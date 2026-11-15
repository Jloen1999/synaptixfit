package com.synaptixfit.domain.port.output.storage;

import java.time.Duration;

/**
 * Almacenamiento de objetos binarios (Cloudflare R2 en producción).
 *
 * <p>El cliente sube y descarga directamente con URLs prefirmadas; el backend firma, borra, descarga
 * cuando la IA lo necesita (o para servir la foto de perfil) y guarda lo que genera él mismo (la foto de
 * perfil ya recortada, ADR 0052).
 */
public interface FileStoragePort {

    PresignedUrl presignUpload(String objectKey, String contentType, long sizeBytes, Duration validity);

    PresignedUrl presignDownload(String objectKey, Duration validity);

    byte[] download(String objectKey);

    /** Guarda desde el servidor un archivo pequeño que el propio backend ha generado (p. ej. la foto de perfil). */
    void put(String objectKey, byte[] content, String contentType);

    void delete(String objectKey);

    /** Borra todo lo que haya bajo una carpeta (p. ej. las fotos de perfil de una cuenta al eliminarla). */
    void deleteFolder(String prefix);

    /** URL pública permanente si el bucket la expone; si no, null. */
    String publicUrl(String objectKey);
}
