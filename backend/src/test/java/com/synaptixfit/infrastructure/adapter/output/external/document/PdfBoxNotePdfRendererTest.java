package com.synaptixfit.infrastructure.adapter.output.external.document;

import static org.assertj.core.api.Assertions.assertThat;

import java.io.IOException;
import org.apache.pdfbox.Loader;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.text.PDFTextStripper;
import org.junit.jupiter.api.Test;

/** El PDF de un apunte (ADR 0064): se lee, conserva acentos y no falla con lo que la fuente no tiene. */
class PdfBoxNotePdfRendererTest {

    private final PdfBoxNotePdfRenderer renderer = new PdfBoxNotePdfRenderer();

    private static String text(byte[] pdf) throws IOException {
        try (PDDocument doc = Loader.loadPDF(pdf)) {
            return new PDFTextStripper().getText(doc);
        }
    }

    @Test
    void writesTitleHeadingsListsAndLinksWithoutMarkdownMarks() throws IOException {
        byte[] pdf = renderer.render("Tema 2: Normalización", """
                # Formas normales
                Una **relación** está en *1FN* si sus valores son atómicos.
                - Dependencia funcional
                1. Primera forma
                > Ojo con la `clave`
                Más en [la guía](https://uni.es/guia) ✅ λ
                ```
                SELECT * FROM t;
                ```
                """);

        assertThat(new String(pdf, 0, 5)).isEqualTo("%PDF-");
        String text = text(pdf);
        assertThat(text).contains("Tema 2: Normalización", "Formas normales",
                "Una relación está en 1FN si sus valores son atómicos.", "Dependencia funcional", "1. Primera forma",
                "Ojo con la clave", "la guía (https://uni.es/guia) ? ?", "SELECT * FROM t;");
        assertThat(text).doesNotContain("**", "](");
    }

    @Test
    void aLongNoteGoesOnSeveralPages() throws IOException {
        byte[] pdf = renderer.render("Largo", "Párrafo con bastante texto para ocupar la línea entera.\n".repeat(200));
        try (PDDocument doc = Loader.loadPDF(pdf)) {
            assertThat(doc.getNumberOfPages()).isGreaterThan(1);
        }
    }

    @Test
    void aHugeNoteStopsAtThePageCapWithAMark() throws IOException {
        byte[] pdf = renderer.render("Enorme", "Línea\n".repeat(20_000));
        try (PDDocument doc = Loader.loadPDF(pdf)) {
            assertThat(doc.getNumberOfPages()).isEqualTo(PdfBoxNotePdfRenderer.MAX_PAGES);
        }
        assertThat(text(pdf)).contains("[…]");
    }
}
