package com.synaptixfit.domain.model.training;

import com.synaptixfit.domain.exception.FieldValidationException;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Nombre de un ejercicio en los idiomas de la app distintos del español (el canónico, que usan las
 * reglas de rutinas). Un idioma vacío se muestra en español. Lo propone la IA y lo revisa la
 * administración antes de guardar.
 */
public record ExerciseNameTranslations(String en, String fr, String pt) {

    public static final List<String> LANGUAGES = List.of("en", "fr", "pt");
    public static final ExerciseNameTranslations EMPTY = new ExerciseNameTranslations(null, null, null);
    static final int MAX_LENGTH = 200;

    public ExerciseNameTranslations {
        en = clean(en, "translations.en");
        fr = clean(fr, "translations.fr");
        pt = clean(pt, "translations.pt");
    }

    /** A partir de un mapa idioma → nombre (los idiomas que no son de la app se ignoran). */
    public static ExerciseNameTranslations of(Map<String, String> byLanguage) {
        return new ExerciseNameTranslations(byLanguage.get("en"), byLanguage.get("fr"), byLanguage.get("pt"));
    }

    /** Solo los idiomas con nombre, en el orden de {@link #LANGUAGES}. */
    public Map<String, String> byLanguage() {
        Map<String, String> names = new LinkedHashMap<>();
        if (en != null) {
            names.put("en", en);
        }
        if (fr != null) {
            names.put("fr", fr);
        }
        if (pt != null) {
            names.put("pt", pt);
        }
        return names;
    }

    public boolean isEmpty() {
        return en == null && fr == null && pt == null;
    }

    private static String clean(String value, String field) {
        if (value == null || value.isBlank()) {
            return null;
        }
        String v = value.strip();
        if (v.length() > MAX_LENGTH) {
            throw new FieldValidationException(field, "INVALID_LENGTH",
                    field + " length must be at most " + MAX_LENGTH);
        }
        return v;
    }
}
