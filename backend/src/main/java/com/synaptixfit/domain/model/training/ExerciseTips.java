package com.synaptixfit.domain.model.training;

import java.util.List;

/**
 * «Las claves» y «Errores comunes» de un ejercicio en un idioma (ADR 0031): frases cortas y sencillas
 * para hacerlo bien. Vacío si el ejercicio aún no tiene consejos (la app no enseña la sección).
 */
public record ExerciseTips(List<String> keyPoints, List<String> commonMistakes) {

    public static final ExerciseTips EMPTY = new ExerciseTips(List.of(), List.of());

    public ExerciseTips {
        keyPoints = clean(keyPoints);
        commonMistakes = clean(commonMistakes);
    }

    public boolean isEmpty() {
        return keyPoints.isEmpty() && commonMistakes.isEmpty();
    }

    private static List<String> clean(List<String> lines) {
        return lines == null ? List.of()
                : lines.stream().filter(l -> l != null && !l.isBlank()).map(String::strip).toList();
    }
}
