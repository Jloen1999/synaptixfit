package com.synaptixfit.domain.model.profile.enrollment;

import java.text.Normalizer;
import java.util.Locale;

/**
 * Comparación de nombres del documento con el catálogo: los documentos suelen venir en mayúsculas,
 * con o sin tildes y con espacios o signos distintos («METODOLOGIA Y DESARROLLO…» frente a
 * «Metodología y desarrollo…»).
 */
public final class CatalogNames {

    private CatalogNames() {
    }

    /** Mayúsculas, sin tildes ni signos y con un solo espacio. */
    public static String normalize(String s) {
        if (s == null) {
            return "";
        }
        return Normalizer.normalize(s, Normalizer.Form.NFD).replaceAll("\\p{M}", "")
                .toUpperCase(Locale.ROOT)
                .replaceAll("[^A-Z0-9 ]", " ")
                .replaceAll("\\s+", " ")
                .strip();
    }

    /** Iguales, o uno contiene al otro (nombres largos partidos o con el centro añadido). */
    public static boolean matches(String a, String b) {
        String x = normalize(a);
        String y = normalize(b);
        if (x.isEmpty() || y.isEmpty()) {
            return false;
        }
        return x.equals(y) || x.contains(y) || y.contains(x);
    }
}
