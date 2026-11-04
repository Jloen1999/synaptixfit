package com.synaptixfit.domain.model.academic;

import com.synaptixfit.domain.exception.academic.NoteScanNothingFoundException;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Borrador de apunte leído de fotos: lo revisa la persona antes de guardarlo (no se guarda solo).
 * {@code tidied} indica si la IA lo ordenó; si no estaba disponible, es el texto tal como se leyó.
 */
public record ScannedNoteDraft(String title, String markdown, boolean tidied, int pages) {

    /** Menos letras o cifras que esto es ruido de la foto (sombras, bordes), no apuntes. */
    static final int MIN_READABLE_CHARS = 12;

    /**
     * Texto máximo que se manda a la IA para ordenarlo (≈ 5 páginas densas). Por encima, la respuesta
     * no cabría entera y se perderían partes: se devuelve el texto tal cual se leyó.
     */
    public static final int MAX_TIDY_CHARS = 20_000;

    static final int TITLE_MAX = 80;

    /** Separador entre páginas: una regla horizontal en Markdown. */
    static final String PAGE_BREAK = "\n\n---\n\n";

    /**
     * Junta el texto de cada página en el orden en que se hicieron las fotos. Si no hay nada legible
     * lanza {@link NoteScanNothingFoundException}: mejor decirlo que dar un apunte vacío.
     */
    public static String joinPages(List<String> pages) {
        String joined = pages.stream()
                .map(p -> p == null ? "" : p.strip())
                .filter(p -> !p.isEmpty())
                .collect(Collectors.joining(PAGE_BREAK));
        long readable = joined.chars().filter(Character::isLetterOrDigit).count();
        if (readable < MIN_READABLE_CHARS) {
            throw new NoteScanNothingFoundException();
        }
        return joined;
    }

    /** Sin IA: el texto leído tal cual y, como título, su primera línea con contenido. */
    public static ScannedNoteDraft untidied(String text, int pages) {
        return new ScannedNoteDraft(firstLineTitle(text), text, false, pages);
    }

    /** Con IA: si no dio título, se usa la primera línea del texto ordenado. */
    public static ScannedNoteDraft tidied(String title, String markdown, int pages) {
        String t = title == null || title.isBlank() ? firstLineTitle(markdown) : shorten(title.strip());
        return new ScannedNoteDraft(t, markdown, true, pages);
    }

    /** Primera línea con letras, sin marcas de Markdown; {@code null} si no hay ninguna. */
    static String firstLineTitle(String text) {
        if (text == null) {
            return null;
        }
        for (String line : text.split("\\R")) {
            String clean = line.replaceAll("^[#>*\\-\\s\\d.)]+", "").strip();
            if (clean.chars().anyMatch(Character::isLetter)) {
                return shorten(clean);
            }
        }
        return null;
    }

    private static String shorten(String s) {
        return s.length() <= TITLE_MAX ? s : s.substring(0, TITLE_MAX - 1).strip() + "…";
    }
}
