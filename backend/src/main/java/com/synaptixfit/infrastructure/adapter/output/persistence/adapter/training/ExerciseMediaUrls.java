package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.training;

import java.util.regex.Matcher;
import java.util.regex.Pattern;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

/**
 * Sirve los vídeos e imágenes de los ejercicios desde la dirección de {@code MEDIA_PUBLIC_BASE_URL} (en producción,
 * {@code https://synaptixfit.jloenit.dev/media}, que nginx reenvía al bucket; ADR 0024) aunque la BD guarde la
 * dirección de desarrollo {@code pub-….r2.dev}. Esa dirección tiene límite de peticiones, no pasa por la caché de
 * Cloudflare y en España algunos operadores bloquean sus IP durante los partidos de fútbol, así que en el móvil los
 * medios dejaban de verse. Sin dirección configurada, las URL salen tal cual.
 */
@Component
public class ExerciseMediaUrls {

    private static final Pattern DEV_BUCKET = Pattern.compile("^https://pub-[0-9a-f]+\\.r2\\.dev/");

    private final String publicBase;

    public ExerciseMediaUrls(@Value("${synaptixfit.media.public-base-url:}") String base) {
        this.publicBase = base == null || base.isBlank() ? null : (base.endsWith("/") ? base : base + "/");
    }

    /** La URL con la dirección pública si la guardada es la de desarrollo del bucket; si no, la misma. */
    public String resolve(String url) {
        if (url == null || publicBase == null) {
            return url;
        }
        return DEV_BUCKET.matcher(url).replaceFirst(Matcher.quoteReplacement(publicBase));
    }
}
