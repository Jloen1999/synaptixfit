package com.synaptixfit.domain.model.academic;

import java.text.Normalizer;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;

/**
 * Freno a la IA que ordena apuntes leídos de fotos (ADR 0051): el texto ordenado debe decir lo mismo que el
 * leído. La IA tiene orden de no añadir nada, pero con un texto muy roto «adivina» y acaba escribiendo un apunte
 * que no se parece a la foto. Lo usa la lectura de apuntes: si el ordenado se aleja, se devuelve el leído.
 */
public final class TidyFidelity {

    /**
     * Parte mínima de las palabras del texto ordenado que deben estar en el leído. Corregir letras cambiadas toca
     * pocas palabras (y las casi iguales cuentan, ver {@link #near}); por debajo del 70 % ya no es corregir, es
     * escribir otra cosa.
     */
    public static final double MIN_SHARED_WORDS = 0.7;

    /** Ordenar no alarga: como mucho la mitad más de palabras (más un margen para títulos cortos). */
    static final double MAX_GROWTH = 1.5;
    static final int GROWTH_MARGIN = 10;

    /** Las palabras de 1-2 letras (artículos, preposiciones) están en cualquier texto: no dicen nada. */
    static final int MIN_WORD_LENGTH = 3;

    private TidyFidelity() {
    }

    /** ¿El texto ordenado se ciñe al leído? Compara palabras sin tildes ni mayúsculas. */
    public static boolean keepsTo(String read, String tidied) {
        List<String> source = words(read);
        List<String> result = words(tidied);
        if (result.isEmpty()) {
            return false;
        }
        if (result.size() > source.size() * MAX_GROWTH + GROWTH_MARGIN) {
            return false;
        }
        Set<String> exact = new HashSet<>(source);
        Map<Character, List<String>> byInitial = new HashMap<>();
        for (String word : exact) {
            byInitial.computeIfAbsent(word.charAt(0), k -> new ArrayList<>()).add(word);
        }
        int shared = 0;
        for (String word : result) {
            if (exact.contains(word) || nearAny(word, byInitial.getOrDefault(word.charAt(0), List.of()))) {
                shared++;
            }
        }
        return shared >= MIN_SHARED_WORDS * result.size();
    }

    /** Palabras de 3 o más letras, en minúsculas y sin tildes («Fotosíntesis» y «fotosintesis» son la misma). */
    static List<String> words(String text) {
        List<String> words = new ArrayList<>();
        if (text == null || text.isBlank()) {
            return words;
        }
        String plain = Normalizer.normalize(text, Normalizer.Form.NFD)
                .replaceAll("\\p{M}+", "")
                .toLowerCase(Locale.ROOT);
        for (String word : plain.split("[^\\p{L}\\p{N}]+")) {
            if (word.length() >= MIN_WORD_LENGTH) {
                words.add(word);
            }
        }
        return words;
    }

    private static boolean nearAny(String word, List<String> candidates) {
        int allowed = allowedEdits(word.length());
        if (allowed == 0) {
            return false;
        }
        for (String candidate : candidates) {
            if (Math.abs(candidate.length() - word.length()) <= allowed && near(word, candidate, allowed)) {
                return true;
            }
        }
        return false;
    }

    /** Corregir una letra mal leída en palabras medianas, dos en las largas; las cortas, iguales. */
    static int allowedEdits(int length) {
        if (length >= 8) {
            return 2;
        }
        return length >= 4 ? 1 : 0;
    }

    /** Distancia de edición (Levenshtein) acotada: corta en cuanto supera {@code max}. */
    static boolean near(String a, String b, int max) {
        int[] previous = new int[b.length() + 1];
        int[] current = new int[b.length() + 1];
        for (int j = 0; j <= b.length(); j++) {
            previous[j] = j;
        }
        for (int i = 1; i <= a.length(); i++) {
            current[0] = i;
            int rowMin = current[0];
            for (int j = 1; j <= b.length(); j++) {
                int cost = a.charAt(i - 1) == b.charAt(j - 1) ? 0 : 1;
                current[j] = Math.min(Math.min(current[j - 1] + 1, previous[j] + 1), previous[j - 1] + cost);
                rowMin = Math.min(rowMin, current[j]);
            }
            if (rowMin > max) {
                return false;
            }
            int[] swap = previous;
            previous = current;
            current = swap;
        }
        return previous[b.length()] <= max;
    }
}
