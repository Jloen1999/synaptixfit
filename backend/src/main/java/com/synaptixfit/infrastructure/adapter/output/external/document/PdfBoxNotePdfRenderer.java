package com.synaptixfit.infrastructure.adapter.output.external.document;

import com.synaptixfit.domain.exception.academic.NotePdfUnavailableException;
import com.synaptixfit.domain.port.output.academic.NotePdfRendererPort;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Pattern;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDDocumentInformation;
import org.apache.pdfbox.pdmodel.PDPage;
import org.apache.pdfbox.pdmodel.PDPageContentStream;
import org.apache.pdfbox.pdmodel.common.PDRectangle;
import org.apache.pdfbox.pdmodel.font.PDFont;
import org.apache.pdfbox.pdmodel.font.PDType1Font;
import org.apache.pdfbox.pdmodel.font.Standard14Fonts;
import org.springframework.stereotype.Component;

/**
 * Implementa {@link NotePdfRendererPort} con PDFBox (ya estaba para leer PDF): un PDF A4 sencillo con el título y el
 * Markdown del apunte (títulos, listas, citas, código y párrafos con ajuste de línea). Las fuentes estándar solo
 * tienen el alfabeto latino (WinAnsi): lo que no cabe en ellas (emojis, griego…) sale como «?» en vez de fallar.
 * Como mucho {@link #MAX_PAGES} páginas (un apunte más largo acaba en «[…]»); un fallo de PDFBox sale como
 * {@link NotePdfUnavailableException}, nunca como un 500 sin {@code code}.
 */
@Component
public class PdfBoxNotePdfRenderer implements NotePdfRendererPort {

    /** Tope de páginas: un apunte normal ocupa pocas; más de 150 no se imprime ni se manda por WhatsApp. */
    static final int MAX_PAGES = 150;
    private static final float MARGIN = 56;
    private static final float BODY = 11;
    private static final Pattern IMAGE = Pattern.compile("!\\[([^\\]]*)]\\([^)]*\\)");
    private static final Pattern LINK = Pattern.compile("\\[([^\\]]+)]\\(([^)]+)\\)");
    private static final Pattern EMPHASIS = Pattern.compile("(\\*\\*|__|\\*|`|~~)");
    private static final Pattern ORDERED = Pattern.compile("^(\\d+)[.)]\\s+(.*)");

    @Override
    public byte[] render(String title, String markdown) {
        try (PDDocument document = new PDDocument(); ByteArrayOutputStream out = new ByteArrayOutputStream()) {
            PDDocumentInformation info = new PDDocumentInformation();
            info.setTitle(title);
            info.setCreator("SynaptixFit");
            document.setDocumentInformation(info);
            Writer writer = new Writer(document);
            writer.paragraph(title, writer.bold, 18, 0);
            writer.gap(BODY);
            boolean code = false;
            for (String raw : (markdown == null ? "" : markdown).split("\\R", -1)) {
                if (writer.full) {
                    break;
                }
                String line = raw.stripTrailing();
                if (line.strip().startsWith("```")) {
                    code = !code;
                    writer.gap(BODY / 2);
                    continue;
                }
                if (code) {
                    writer.paragraph(line.isEmpty() ? " " : line, writer.mono, BODY - 1, 12);
                    continue;
                }
                writeLine(writer, line.strip());
            }
            writer.close();
            document.save(out);
            return out.toByteArray();
        } catch (IOException | RuntimeException e) {
            throw new NotePdfUnavailableException(e.getClass().getSimpleName());
        }
    }

    private static void writeLine(Writer w, String line) throws IOException {
        if (line.isEmpty()) {
            w.gap(BODY / 2);
        } else if (line.matches("^(-{3,}|\\*{3,}|_{3,})$")) {
            w.gap(BODY);
        } else if (line.startsWith("#")) {
            int level = Math.min(line.indexOf(' ') < 0 ? 1 : line.indexOf(' '), 6);
            String text = inline(line.replaceFirst("^#+\\s*", ""));
            w.gap(BODY / 2);
            w.paragraph(text, w.bold, level == 1 ? 16 : level == 2 ? 14 : 12, 0);
        } else if (line.startsWith(">")) {
            w.paragraph(inline(line.replaceFirst("^>+\\s?", "")), w.italic, BODY, 16);
        } else if (line.matches("^[-*+]\\s+.*")) {
            String text = inline(line.substring(1).strip().replaceFirst("^\\[[ xX]]\\s*", ""));
            w.paragraph("• " + text, w.regular, BODY, 12);
        } else if (ORDERED.matcher(line).matches()) {
            var m = ORDERED.matcher(line);
            m.matches();
            w.paragraph(m.group(1) + ". " + inline(m.group(2)), w.regular, BODY, 12);
        } else if (line.startsWith("|")) {
            if (!line.matches("^\\|?[\\s:|-]+\\|?$")) {
                w.paragraph(inline(line.replaceAll("^\\||\\|$", "").replace("|", "  |  ").strip()), w.regular,
                        BODY, 0);
            }
        } else {
            w.paragraph(inline(line), w.regular, BODY, 0);
        }
    }

    /** Quita las marcas en línea: imágenes por su texto alternativo, enlaces como «texto (dirección)», énfasis. */
    static String inline(String text) {
        String s = IMAGE.matcher(text).replaceAll("$1");
        s = LINK.matcher(s).replaceAll("$1 ($2)");
        return EMPHASIS.matcher(s).replaceAll("");
    }

    /** Escribe líneas ajustadas al ancho y abre páginas nuevas cuando hace falta. */
    private static final class Writer {

        final PDFont regular = new PDType1Font(Standard14Fonts.FontName.HELVETICA);
        final PDFont bold = new PDType1Font(Standard14Fonts.FontName.HELVETICA_BOLD);
        final PDFont italic = new PDType1Font(Standard14Fonts.FontName.HELVETICA_OBLIQUE);
        final PDFont mono = new PDType1Font(Standard14Fonts.FontName.COURIER);
        private final PDDocument document;
        private final Map<String, Boolean> encodable = new HashMap<>();
        private final float width = PDRectangle.A4.getWidth() - 2 * MARGIN;
        private PDPageContentStream stream;
        private float y;
        /** Ya no caben más páginas: el resto del apunte se deja fuera. */
        private boolean full;

        Writer(PDDocument document) throws IOException {
            this.document = document;
            newPage();
        }

        void gap(float amount) {
            y -= amount;
        }

        void paragraph(String text, PDFont font, float size, float indent) throws IOException {
            if (full) {
                return;
            }
            String safe = sanitize(text, font);
            for (String line : wrap(safe, font, size, width - indent)) {
                float leading = size * 1.4f;
                if (y - leading < MARGIN) {
                    if (document.getNumberOfPages() >= MAX_PAGES) {
                        markTruncated();
                        return;
                    }
                    newPage();
                }
                y -= leading;
                stream.beginText();
                stream.setFont(font, size);
                stream.newLineAtOffset(MARGIN + indent, y);
                stream.showText(line);
                stream.endText();
            }
        }

        /** Cierra la última página con «[…]» y no escribe nada más. */
        private void markTruncated() throws IOException {
            full = true;
            stream.beginText();
            stream.setFont(regular, BODY);
            stream.newLineAtOffset(MARGIN, MARGIN / 2);
            stream.showText("[…]");
            stream.endText();
        }

        void close() throws IOException {
            stream.close();
        }

        private void newPage() throws IOException {
            if (stream != null) {
                stream.close();
            }
            PDPage page = new PDPage(PDRectangle.A4);
            document.addPage(page);
            stream = new PDPageContentStream(document, page);
            y = PDRectangle.A4.getHeight() - MARGIN;
        }

        private List<String> wrap(String text, PDFont font, float size, float max) throws IOException {
            List<String> lines = new ArrayList<>();
            StringBuilder current = new StringBuilder();
            for (String word : text.split(" ")) {
                String candidate = current.isEmpty() ? word : current + " " + word;
                if (width(candidate, font, size) <= max) {
                    current.setLength(0);
                    current.append(candidate);
                    continue;
                }
                if (!current.isEmpty()) {
                    lines.add(current.toString());
                    current.setLength(0);
                }
                // Una palabra más larga que la línea (una dirección web) se parte por caracteres.
                for (char c : word.toCharArray()) {
                    if (width(current.toString() + c, font, size) > max && !current.isEmpty()) {
                        lines.add(current.toString());
                        current.setLength(0);
                    }
                    current.append(c);
                }
            }
            if (!current.isEmpty() || lines.isEmpty()) {
                lines.add(current.toString());
            }
            return lines;
        }

        private static float width(String text, PDFont font, float size) throws IOException {
            return font.getStringWidth(text) / 1000 * size;
        }

        private String sanitize(String text, PDFont font) {
            StringBuilder sb = new StringBuilder(text.length());
            text.replace('\t', ' ').codePoints().forEach(cp -> {
                String ch = new String(Character.toChars(cp));
                boolean ok = encodable.computeIfAbsent(font.getName() + ch, k -> canEncode(font, ch));
                sb.append(ok ? ch : "?");
            });
            return sb.toString();
        }

        private static boolean canEncode(PDFont font, String ch) {
            try {
                font.encode(ch);
                return true;
            } catch (IllegalArgumentException | IOException e) {
                return false;
            }
        }
    }
}
