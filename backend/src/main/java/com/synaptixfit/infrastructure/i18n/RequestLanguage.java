package com.synaptixfit.infrastructure.i18n;

import java.util.Locale;
import java.util.Set;
import org.springframework.context.i18n.LocaleContextHolder;
import org.springframework.web.context.request.RequestContextHolder;

/**
 * Idioma de la petición en curso (la app lo envía en {@code Accept-Language}): es, en, fr o pt.
 * Fuera de una petición o con un idioma no admitido, español. Lo usan la IA (en qué idioma escribe) y
 * las respuestas REST (nombres del catálogo); el dominio no sabe de idiomas.
 */
public final class RequestLanguage {

    public static final String DEFAULT = "es";
    static final Set<String> SUPPORTED = Set.of("es", "en", "fr", "pt");

    private RequestLanguage() {
    }

    public static String code() {
        if (RequestContextHolder.getRequestAttributes() == null) {
            return DEFAULT;
        }
        return codeOf(LocaleContextHolder.getLocale());
    }

    static String codeOf(Locale locale) {
        String language = locale == null ? DEFAULT : locale.getLanguage();
        return SUPPORTED.contains(language) ? language : DEFAULT;
    }
}
