package com.synaptixfit.domain.model.privacy;

import com.synaptixfit.domain.model.shared.Guard;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

/**
 * Un texto legal listo para mostrar (ADR 0034): título, bloques y datos de contacto ya puestos. Se compone a
 * partir de un texto sencillo («# título», «## sección», «- punto» y párrafos) con marcadores que se rellenan con
 * la configuración del servidor, así la web pública y la app enseñan exactamente lo mismo.
 */
public record LegalDocument(LegalDocumentKind kind, String language, String version, String title,
                            List<LegalBlock> blocks, boolean contactConfigured) {

    /** Marcadores del texto fuente. */
    static final String CONTROLLER = "{{RESPONSABLE}}";
    static final String EMAIL = "{{CORREO}}";
    static final String VERSION = "{{VERSION}}";
    static final String APP_URL = "{{APP_URL}}";

    public LegalDocument {
        Guard.notNull(kind, "kind");
        language = Guard.notBlank(language, "language");
        version = Guard.notBlank(version, "version");
        title = Guard.notBlank(title, "title");
        blocks = List.copyOf(Guard.notNull(blocks, "blocks"));
    }

    /**
     * Rellena los marcadores y separa el texto en bloques. Sin responsable o correo configurados se escribe
     * «pendiente»: es mejor un hueco honesto que un dato inventado.
     */
    public static LegalDocument compose(LegalDocumentKind kind, String language, String source, LegalContact contact,
                                        String appUrl) {
        Guard.notNull(contact, "contact");
        String pending = "en".equals(language.toLowerCase(Locale.ROOT)) ? "(to be provided)" : "(pendiente de indicar)";
        String text = Guard.notBlank(source, "source");
        if (appUrl == null || appUrl.isBlank()) {
            // Sin la dirección pública configurada, las frases que la citan se quitan enteras: mejor que dejarlas
            // rotas («desde la web, .»).
            text = String.join(System.lineSeparator(), text.lines().filter(line -> !line.contains(APP_URL)).toList());
        }
        String filled = text
                .replace(CONTROLLER, contact.controllerName() == null ? pending : contact.controllerName())
                .replace(EMAIL, contact.contactEmail() == null ? pending : contact.contactEmail())
                .replace(VERSION, LegalTerms.CURRENT_VERSION)
                .replace(APP_URL, appUrl == null || appUrl.isBlank() ? "" : stripSlash(appUrl.trim()));

        String title = null;
        List<LegalBlock> blocks = new ArrayList<>();
        StringBuilder paragraph = new StringBuilder();
        for (String raw : filled.split("\\R")) {
            String line = raw.strip();
            if (line.isEmpty()) {
                flush(paragraph, blocks);
            } else if (line.startsWith("## ")) {
                flush(paragraph, blocks);
                blocks.add(new LegalBlock(LegalBlock.Type.HEADING, line.substring(3).strip()));
            } else if (line.startsWith("# ")) {
                flush(paragraph, blocks);
                title = line.substring(2).strip();
            } else if (line.startsWith("- ")) {
                flush(paragraph, blocks);
                blocks.add(new LegalBlock(LegalBlock.Type.BULLET, line.substring(2).strip()));
            } else {
                if (!paragraph.isEmpty()) {
                    paragraph.append(' ');
                }
                paragraph.append(line);
            }
        }
        flush(paragraph, blocks);
        return new LegalDocument(kind, language, LegalTerms.CURRENT_VERSION, title == null ? kind.slug() : title,
                blocks, contact.configured());
    }

    private static void flush(StringBuilder paragraph, List<LegalBlock> blocks) {
        if (!paragraph.isEmpty()) {
            blocks.add(new LegalBlock(LegalBlock.Type.PARAGRAPH, paragraph.toString()));
            paragraph.setLength(0);
        }
    }

    private static String stripSlash(String url) {
        return url.endsWith("/") ? url.substring(0, url.length() - 1) : url;
    }
}
