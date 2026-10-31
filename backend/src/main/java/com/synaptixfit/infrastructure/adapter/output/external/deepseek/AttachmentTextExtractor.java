package com.synaptixfit.infrastructure.adapter.output.external.deepseek;

import com.synaptixfit.domain.exception.AiAttachmentNotSupportedException;
import com.synaptixfit.domain.port.output.ai.AiAttachment;
import com.synaptixfit.infrastructure.adapter.output.external.document.PdfTextExtractor;
import java.nio.charset.StandardCharsets;
import org.springframework.stereotype.Component;

/**
 * Convierte los adjuntos de un prompt en texto, porque DeepSeek solo lee texto. Lo usa
 * {@link DeepSeekAiAdapter} antes de llamar a la API.
 *
 * <p>PDF con texto → texto (PDFBox); ficheros de texto → tal cual. Imágenes y PDF escaneados
 * (sin capa de texto) no se pueden leer: {@link AiAttachmentNotSupportedException}.
 */
@Component
public class AttachmentTextExtractor {

    /** Límite por documento (~15 000 tokens) para no desbordar el contexto del modelo. */
    static final int MAX_CHARS = 60_000;

    public String toText(AiAttachment attachment) {
        String mime = attachment.mimeType() == null ? "" : attachment.mimeType().toLowerCase();
        String text;
        if (mime.equals("application/pdf")) {
            text = pdfText(attachment.data());
        } else if (mime.startsWith("text/") || mime.equals("application/json")) {
            text = new String(attachment.data(), StandardCharsets.UTF_8);
        } else {
            throw new AiAttachmentNotSupportedException(mime);
        }
        if (text.isBlank()) {
            // PDF escaneado: son imágenes, no hay texto que extraer.
            throw new AiAttachmentNotSupportedException(mime + " (sin texto)");
        }
        return text.length() > MAX_CHARS ? text.substring(0, MAX_CHARS) : text;
    }

    private static String pdfText(byte[] data) {
        // Un PDF dañado es un problema del archivo, no del servicio: reintentar no lo arregla.
        return PdfTextExtractor.text(data)
                .orElseThrow(() -> new AiAttachmentNotSupportedException("application/pdf (dañado)"));
    }
}
