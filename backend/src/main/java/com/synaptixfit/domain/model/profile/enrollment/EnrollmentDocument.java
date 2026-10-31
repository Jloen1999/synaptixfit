package com.synaptixfit.domain.model.profile.enrollment;

import com.synaptixfit.domain.exception.profile.EnrollmentFileInvalidException;
import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.Locale;

/**
 * Documento de matrícula recibido: un PDF de hasta {@link #MAX_BYTES}. Se comprueba el tipo declarado y
 * la firma {@code %PDF-} del contenido, para no procesar otros archivos. Solo vive en memoria.
 */
public record EnrollmentDocument(byte[] content) {

    /** Una carta de pago ocupa unos cientos de KB; 5 MB deja margen sin aceptar cualquier cosa. */
    public static final int MAX_BYTES = 5 * 1024 * 1024;
    public static final String MIME = "application/pdf";
    private static final byte[] SIGNATURE = "%PDF-".getBytes(StandardCharsets.US_ASCII);

    public EnrollmentDocument {
        if (content == null || content.length < SIGNATURE.length || content.length > MAX_BYTES
                || !Arrays.equals(Arrays.copyOf(content, SIGNATURE.length), SIGNATURE)) {
            throw new EnrollmentFileInvalidException();
        }
    }

    public static EnrollmentDocument of(byte[] content, String mimeType) {
        String mime = mimeType == null ? "" : mimeType.toLowerCase(Locale.ROOT).strip();
        if (!mime.equals(MIME)) {
            throw new EnrollmentFileInvalidException();
        }
        return new EnrollmentDocument(content);
    }
}
