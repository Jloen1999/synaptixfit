package com.synaptixfit.domain.model.planner;

import java.text.Normalizer;
import java.util.Arrays;
import java.util.List;
import java.util.Locale;
import java.util.Optional;
import java.util.Set;
import java.util.regex.Pattern;

/**
 * Empareja textos externos (resumen de un evento ICS, asignatura leída por la IA) con las
 * asignaturas del usuario, sin distinguir mayúsculas ni tildes.
 */
public final class SubjectMatcher {

    /** Palabras que no cuentan para las siglas («Estructura de Computadores» → «ec»). */
    private static final Set<String> STOP_WORDS = Set.of("de", "del", "la", "las", "el", "los", "y", "e", "a",
            "en", "para", "por", "al", "con", "of", "and", "the", "to", "for", "in", "et", "des", "du", "le", "da",
            "do", "das", "dos", "o", "i", "ii", "iii", "iv");

    /**
     * Palabras demasiado corrientes en nombres de asignaturas para decidir por sí solas que un calendario es de
     * una («Fundamentos», «Introducción»…).
     */
    private static final Set<String> GENERIC_WORDS = Set.of("fundamentos", "introduccion", "principios",
            "tecnicas", "teoria", "avanzada", "avanzadas", "avanzado", "avanzados", "aplicada", "aplicadas",
            "aplicado", "basica", "basicas", "general", "practicas", "metodos", "sistemas", "ingenieria",
            "informatica", "gestion", "analisis", "diseno", "desarrollo", "tecnologia", "tecnologias", "datos");

    private SubjectMatcher() {
    }

    /**
     * ¿Comparten el texto y el nombre de la asignatura alguna palabra distintiva (5 letras o más, no genérica)?
     * Sirve para el nombre o la descripción de un calendario: «1_1_GII_GITT_Programación» o «Asignatura:
     * Programación» son de «Fundamentos de la Programación», aunque sus eventos se titulen «PR1_GG_T2».
     */
    public static boolean sharesDistinctiveWord(String text, String subjectName) {
        Set<String> words = new java.util.HashSet<>(Arrays.asList(normalize(text).split(" ")));
        return Arrays.stream(normalize(subjectName).split(" "))
                .filter(w -> w.length() >= 5 && !GENERIC_WORDS.contains(w))
                .anyMatch(words::contains);
    }

    /**
     * Siglas de la asignatura: iniciales de las palabras significativas («Interacción Persona-Ordenador» →
     * «ipo»). Los calendarios de los profesores suelen titular así los eventos («EC_GG_Sesiones 1 y 2»).
     * Vacío si salen menos de 2 letras.
     */
    public static String acronym(String subjectName) {
        StringBuilder out = new StringBuilder();
        for (String word : normalize(subjectName).split(" ")) {
            if (!word.isEmpty() && !STOP_WORDS.contains(word) && Character.isLetter(word.charAt(0))) {
                out.append(word.charAt(0));
            }
        }
        return out.length() >= 2 ? out.toString() : "";
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
     * ¿El texto menciona la asignatura? Coincide si contiene el nombre o el código, sus siglas en mayúsculas
     * como palabra suelta («EC_GG_Tema 5», «2_3_GIIT_EC»), o al menos el 60 % de las palabras significativas (más de 2
     * letras) del nombre.
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
        // Siglas solo en MAYÚSCULAS y como palabra suelta en el texto original: «al» o «es» son palabras
        // corrientes y asignarían entregas a la asignatura equivocada («Entrega al profesor»).
        String initials = acronym(subjectName).toUpperCase(Locale.ROOT);
        if (!initials.isEmpty() && text != null
                && Pattern.compile("(?<![\\p{L}\\p{N}])" + Pattern.quote(initials) + "(?![\\p{L}\\p{N}])")
                        .matcher(text).find()) {
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
