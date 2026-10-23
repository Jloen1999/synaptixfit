package com.synaptixfit.infrastructure.adapter.output.external.deepseek;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.domain.exception.AiAttachmentNotSupportedException;
import com.synaptixfit.domain.port.output.ai.AiAttachment;
import java.io.ByteArrayOutputStream;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDPage;
import org.apache.pdfbox.pdmodel.PDPageContentStream;
import org.apache.pdfbox.pdmodel.font.PDType1Font;
import org.apache.pdfbox.pdmodel.font.Standard14Fonts;
import org.junit.jupiter.api.Test;

/** Conversión de adjuntos a texto: PDF con texto, PDF sin texto e imágenes. */
class AttachmentTextExtractorTest {

    private final AttachmentTextExtractor extractor = new AttachmentTextExtractor();

    /** Crea un PDF de una página; con {@code text} null la página queda vacía (como un escaneo). */
    private static byte[] pdf(String text) throws Exception {
        try (PDDocument doc = new PDDocument(); ByteArrayOutputStream out = new ByteArrayOutputStream()) {
            PDPage page = new PDPage();
            doc.addPage(page);
            if (text != null) {
                try (PDPageContentStream stream = new PDPageContentStream(doc, page)) {
                    stream.beginText();
                    stream.setFont(new PDType1Font(Standard14Fonts.FontName.HELVETICA), 12);
                    stream.newLineAtOffset(50, 700);
                    stream.showText(text);
                    stream.endText();
                }
            }
            doc.save(out);
            return out.toByteArray();
        }
    }

    @Test
    void extractsTextFromPdf() throws Exception {
        assertThat(extractor.toText(new AiAttachment("application/pdf", pdf("Calculo I - Lunes 9:00"))))
                .contains("Calculo I - Lunes 9:00");
    }

    @Test
    void pdfWithoutTextIsNotSupported() throws Exception {
        assertThatThrownBy(() -> extractor.toText(new AiAttachment("application/pdf", pdf(null))))
                .isInstanceOf(AiAttachmentNotSupportedException.class);
    }

    @Test
    void imagesAreNotSupported() {
        assertThatThrownBy(() -> extractor.toText(new AiAttachment("image/jpeg", new byte[]{1, 2})))
                .isInstanceOf(AiAttachmentNotSupportedException.class);
    }
}
