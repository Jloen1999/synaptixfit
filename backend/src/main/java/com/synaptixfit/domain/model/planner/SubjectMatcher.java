package com.synaptixfit.domain.model.planner;

import java.text.Normalizer;
import java.util.Arrays;
import java.util.List;
import java.util.Locale;
import java.util.Optional;

/**
 * Empareja textos externos (resumen de un evento ICS, asignatura leída por la IA) con las
 * asignaturas del usuario, sin distinguir mayúsculas ni tildes.
 */
public final class SubjectMatcher {

    private SubjectMatcher() {
    }

    /** Minúsculas, sin tildes y con espacios simples. */
    public static String normalize(String text) {
        if (text == null) {
            return "";
        }
        String decomposed = Normalizer.normalize(text, Normalizer.Form.NFD).replaceAll("\\p{M}", "");
        return decomposed.toLowerCase(Locale.ROOT).replaceAll("[^a-z0-9]+", " ").strip();
    }

    /** Busca por código exacto, después por nombre exacto y por último por inclusión mutua del nombre. */
    public static Optional<SubjectRef> match(String code, String name, List<SubjectRef> subjects) {
        String c = normalize(code);
        if (!c.isEmpty()) {
            for (SubjectRef s : subjects) {
                if (!normalize(s.code()).isEmpty() && normalize(s.code()).equals(c)) {
                    return Optional.of(s);
                }
            }
        }
        String n = normalize(name);
        if (n.isEmpty()) {
            return Optional.empty();
        }
        for (SubjectRef s : subjects) {
            if (normalize(s.name()).equals(n)) {
                return Optional.of(s);
            }
        }
        for (SubjectRef s : subjects) {
            String sn = normalize(s.name());
            if (!sn.isEmpty() && (sn.contains(n) || n.contains(sn))) {
                return Optional.of(s);
            }
        }
        return Optional.empty();
    }

    /**
     * ¿El texto menciona la asignatura? Coincide si contiene el nombre o el código, o al menos el 60 %
     * de las palabras significativas (más de 2 letras) del nombre.
     */
    public static boolean mentions(String text, String subjectName, String subjectCode) {
        String t = normalize(text);
        String n = normalize(subjectName);
        if (!n.isEmpty() && t.contains(n)) {
            return true;
        }
        String c = normalize(subjectCode);
        if (!c.isEmpty() && t.contains(c)) {
            return true;
        }
        List<String> words = Arrays.stream(n.split(" ")).filter(w -> w.length() > 2).toList();
        if (words.isEmpty()) {
            return false;
        }
        long hits = words.stream().filter(t::contains).count();
        return (double) hits / words.size() >= 0.6;
    }
}
