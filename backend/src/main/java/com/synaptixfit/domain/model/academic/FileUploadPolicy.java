package com.synaptixfit.domain.model.academic;

import com.synaptixfit.domain.exception.FieldValidationException;
import com.synaptixfit.domain.exception.academic.FileTooLargeException;
import com.synaptixfit.domain.exception.academic.FileTypeNotAllowedException;
import com.synaptixfit.domain.model.shared.Guard;
import java.time.Instant;
import java.util.Locale;
import java.util.Set;
import java.util.UUID;

/**
 * Reglas de subida de archivos de asignatura: tipos MIME permitidos, tamaño máximo (25 MB) y
 * jerarquía estricta de claves {@code usuarios/{userId}/asignaturas/{subjectId}/archivos/{ts}_{nombre}}
 * (evita colisiones y permite comprobar la propiedad de una clave).
 */
public final class FileUploadPolicy {

    public static final long MAX_SIZE_BYTES = 25L * 1024 * 1024;

    public static final Set<String> ALLOWED_MIME_TYPES = Set.of(
            "application/pdf",
            "image/png", "image/jpeg", "image/gif", "image/webp", "image/heic", "image/bmp",
            "application/vnd.ms-powerpoint",
            "application/vnd.openxmlformats-officedocument.presentationml.presentation",
            "application/msword",
            "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
            "application/vnd.ms-excel",
            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            "application/vnd.oasis.opendocument.text",
            "application/vnd.oasis.opendocument.presentation",
            "application/vnd.oasis.opendocument.spreadsheet",
            "application/rtf",
            "text/plain", "text/markdown", "text/csv",
            "application/zip");

    private FileUploadPolicy() {
    }

    /** Valida tipo y tamaño. Devuelve el tipo MIME normalizado. */
    public static String validate(String mimeType, long sizeBytes) {
        String mime = normalizeMime(mimeType);
        if (!ALLOWED_MIME_TYPES.contains(mime)) {
            throw new FileTypeNotAllowedException(mime);
        }
        if (sizeBytes <= 0) {
            throw new FieldValidationException("sizeBytes", "OUT_OF_RANGE",
                    "sizeBytes must be positive");
        }
        if (sizeBytes > MAX_SIZE_BYTES) {
            throw new FileTooLargeException(sizeBytes, MAX_SIZE_BYTES);
        }
        return mime;
    }

    public static String normalizeMime(String mimeType) {
        String mime = Guard.notBlank(mimeType, "mimeType").toLowerCase(Locale.ROOT);
        int semicolon = mime.indexOf(';');
        return semicolon >= 0 ? mime.substring(0, semicolon).strip() : mime;
    }

    /** Sustituye todo lo que no sea letra, dígito, punto, guion o guion bajo por «_». */
    public static String sanitizeFileName(String fileName) {
        String name = Guard.length(fileName, "fileName", 1, 255);
        String clean = name.replaceAll("[^\\w.\\-]+", "_").replaceAll("_+", "_");
        return clean.isBlank() || clean.equals("_") ? "archivo" : clean;
    }

    public static String keyPrefix(UUID userId, UUID subjectId) {
        return "usuarios/" + userId + "/asignaturas/" + subjectId + "/archivos/";
    }

    public static String objectKey(UUID userId, UUID subjectId, String fileName, Instant now) {
        return keyPrefix(userId, subjectId) + now.toEpochMilli() + "_" + sanitizeFileName(fileName);
    }

    /** Una clave pertenece al usuario y asignatura si cuelga de su prefijo y no intenta salir de él. */
    public static boolean isKeyOf(String objectKey, UUID userId, UUID subjectId) {
        if (objectKey == null || objectKey.contains("..")) {
            return false;
        }
        String prefix = keyPrefix(userId, subjectId);
        return objectKey.startsWith(prefix) && objectKey.length() > prefix.length()
                && objectKey.indexOf('/', prefix.length()) < 0;
    }
}
