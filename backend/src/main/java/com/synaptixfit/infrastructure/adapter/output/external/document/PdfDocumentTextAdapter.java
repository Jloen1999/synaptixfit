package com.synaptixfit.infrastructure.adapter.output.external.document;

import com.synaptixfit.domain.exception.AiAttachmentNotSupportedException;
import com.synaptixfit.domain.exception.profile.EnrollmentFileInvalidException;
import com.synaptixfit.domain.port.output.profile.DocumentTextPort;
import org.springframework.stereotype.Component;

/** Implementa {@link DocumentTextPort} con {@link PdfTextExtractor}: en memoria y sin guardar nada. */
@Component
public class PdfDocumentTextAdapter implements DocumentTextPort {

    @Override
    public String textOf(byte[] content, String mimeType) {
        String text = PdfTextExtractor.text(content).orElseThrow(EnrollmentFileInvalidException::new);
        if (text.isBlank()) {
            // PDF escaneado: son imágenes, no hay texto que leer.
            throw new AiAttachmentNotSupportedException(mimeType + " (sin texto)");
        }
        return text;
    }
}
