package com.synaptixfit.domain.port.output.storage;

import java.time.Duration;

/**
 * Almacenamiento de objetos binarios (Cloudflare R2 en producción).
 *
 * <p>El cliente sube y descarga directamente con URLs prefirmadas; el backend solo firma, borra
 * y, cuando la IA lo necesita, descarga.
 */
public interface FileStoragePort {

    PresignedUrl presignUpload(String objectKey, String contentType, long sizeBytes, Duration validity);

    PresignedUrl presignDownload(String objectKey, Duration validity);

    byte[] download(String objectKey);

    void delete(String objectKey);

    /** URL pública permanente si el bucket la expone; si no, null. */
    String publicUrl(String objectKey);
}
