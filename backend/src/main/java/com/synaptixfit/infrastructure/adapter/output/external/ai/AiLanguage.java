package com.synaptixfit.infrastructure.adapter.output.external.ai;

import com.synaptixfit.infrastructure.i18n.RequestLanguage;
import java.util.Locale;

/**
 * Idioma en que la IA escribe lo que va a leer la persona: el de la petición en curso (la app envía
 * su idioma en {@code Accept-Language}). Fuera de una petición (tareas en segundo plano) o con un
 * idioma no admitido, español. Es un detalle del prompt: el dominio no sabe de idiomas.
 */
public final class AiLanguage {

    private AiLanguage() {
    }

    /** Nombre del idioma tal como se escribe en un prompt en español («inglés»). */
    public static String current() {
        return nameOf(Locale.forLanguageTag(RequestLanguage.code()));
    }

    /** Regla para el final de un prompt: «Escribe en inglés.». */
    public static String rule() {
        return "Escribe en " + current() + ".";
    }

    static String nameOf(Locale locale) {
        return switch (locale.getLanguage()) {
            case "en" -> "inglés";
            case "fr" -> "francés";
            case "pt" -> "portugués";
            default -> "español";
        };
    }
}
