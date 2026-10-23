package com.synaptixfit.domain.model.academic;

import com.synaptixfit.domain.model.shared.Guard;
import java.time.Instant;
import java.util.Locale;
import java.util.Objects;
import java.util.UUID;

/**
 * Metadatos de un archivo adjunto a una asignatura. El binario vive en el almacenamiento de
 * objetos bajo {@code objectKey}; {@code storedUrl} es la URL pública si el bucket la expone.
 */
public record SubjectFile(UUID id, UUID userId, UUID subjectId, String fileName, String objectKey,
                          String storedUrl, long sizeBytes, String mimeType, Instant createdAt) {

    public SubjectFile {
        Objects.requireNonNull(id, "id");
        Objects.requireNonNull(userId, "userId");
        Objects.requireNonNull(subjectId, "subjectId");
        fileName = Guard.length(fileName, "fileName", 1, 255);
        objectKey = Guard.notBlank(objectKey, "objectKey");
        if (sizeBytes < 0) {
            sizeBytes = 0;
        }
        Objects.requireNonNull(createdAt, "createdAt");
    }

    /** La IA solo admite PDF e imágenes como material multimodal. */
    public boolean isAiReadable() {
        String mime = mimeType == null ? "" : mimeType.toLowerCase(Locale.ROOT);
        return mime.equals("application/pdf") || mime.startsWith("image/");
    }
}
