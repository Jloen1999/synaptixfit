package com.synaptixfit.domain.model.academic;

import com.synaptixfit.domain.exception.FieldValidationException;
import com.synaptixfit.domain.exception.academic.FileTooLargeException;
import com.synaptixfit.domain.exception.academic.FileTypeNotAllowedException;
import java.time.Instant;
import java.util.UUID;

/**
 * Reglas de subida del plan docente antes de tener asignatura: solo PDF (la IA lee su texto; un PDF
 * escaneado sin texto falla con {@code AI_ATTACHMENT_UNSUPPORTED}), 15 MB como máximo y claves bajo
 * {@code usuarios/{userId}/planes-docentes/{ts}_{nombre}} para poder comprobar la propiedad.
 */
public final class TeachingGuideUploadPolicy {

    public static final long MAX_SIZE_BYTES = 15L * 1024 * 1024;
    public static final String PDF = "application/pdf";

    private TeachingGuideUploadPolicy() {
    }

    public static String validate(String mimeType, long sizeBytes) {
        String mime = FileUploadPolicy.normalizeMime(mimeType);
        if (!PDF.equals(mime)) {
            throw new FileTypeNotAllowedException(mime);
        }
        if (sizeBytes <= 0) {
            throw new FieldValidationException("sizeBytes", "OUT_OF_RANGE", "sizeBytes must be positive");
        }
        if (sizeBytes > MAX_SIZE_BYTES) {
            throw new FileTooLargeException(sizeBytes, MAX_SIZE_BYTES);
        }
        return mime;
    }

    public static String keyPrefix(UUID userId) {
        return "usuarios/" + userId + "/planes-docentes/";
    }

    public static String objectKey(UUID userId, String fileName, Instant now) {
        return keyPrefix(userId) + now.toEpochMilli() + "_" + FileUploadPolicy.sanitizeFileName(fileName);
    }

    public static boolean isKeyOf(String objectKey, UUID userId) {
        if (objectKey == null || objectKey.contains("..")) {
            return false;
        }
        String prefix = keyPrefix(userId);
        return objectKey.startsWith(prefix) && objectKey.length() > prefix.length()
                && objectKey.indexOf('/', prefix.length()) < 0;
    }
}
