package com.synaptixfit.infrastructure.adapter.output.external.document;

import java.io.IOException;
import java.util.Optional;
import org.apache.pdfbox.Loader;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.text.PDFTextStripper;

/**
 * Texto de un PDF con PDFBox, en memoria. Vacío si el PDF está dañado o no es un PDF; texto en blanco
 * si es escaneado (sin capa de texto). Lo comparten la lectura de documentos y los adjuntos de la IA,
 * que deciden qué error dar en cada caso.
 */
public final class PdfTextExtractor {

    private PdfTextExtractor() {
    }

    public static Optional<String> text(byte[] pdf) {
        try (PDDocument document = Loader.loadPDF(pdf)) {
            return Optional.of(new PDFTextStripper().getText(document).strip());
        } catch (IOException damaged) {
            return Optional.empty();
        }
    }
}
