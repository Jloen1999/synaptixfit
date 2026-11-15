package com.synaptixfit.domain.model.academic;

import java.util.List;

/**
 * Texto leído de una foto de apuntes y cuánto se fía de él el lector. Lo devuelve {@code ImageTextReaderPort}
 * y lo usa la lectura de apuntes para decidir si pedir ayuda al lector con visión y si dejar que la IA ordene el
 * texto (ADR 0051).
 *
 * @param confidence confianza media de las palabras (0-100), o {@link #UNKNOWN} si el lector no la da (un
 *                   modelo con visión transcribe sin puntuar cada palabra)
 */
public record PageReading(String text, int confidence) {

    public static final int UNKNOWN = -1;

    /**
     * Por debajo de esta confianza media el texto es más ruido que apunte. Tesseract da 85-95 con texto impreso
     * bien iluminado, 60-80 con letra clara a mano y menos de 50 con fotos tumbadas, movidas o en sombra, que es
     * cuando inventa letras; 60 es el corte que recomienda su documentación para descartar palabras dudosas.
     */
    public static final int LOW_CONFIDENCE = 60;

    public PageReading {
        text = text == null ? "" : text;
        confidence = confidence < 0 ? UNKNOWN : Math.min(confidence, 100);
    }

    /**
     * Lectura con la confianza media de sus palabras, ponderada por su longitud: una palabra larga mal leída pesa
     * más que una coma suelta, que Tesseract suele puntuar bajo aunque el resto esté bien. Sin palabras, 0.
     */
    public static PageReading of(String text, List<Word> words) {
        long weighted = 0;
        long letters = 0;
        for (Word word : words) {
            if (word.confidence() < 0 || word.text().isBlank()) {
                continue;
            }
            int length = word.text().strip().length();
            weighted += (long) Math.min(word.confidence(), 100) * length;
            letters += length;
        }
        return new PageReading(text, letters == 0 ? 0 : (int) Math.round((double) weighted / letters));
    }

    /** Lectura de un lector que no puntúa sus palabras. */
    public static PageReading unscored(String text) {
        return new PageReading(text, UNKNOWN);
    }

    /** El lector duda de lo que ha leído: ni se ordena con IA ni se da por bueno sin avisar. */
    public boolean unclear() {
        return confidence != UNKNOWN && confidence < LOW_CONFIDENCE;
    }

    public boolean hasText() {
        return text.chars().anyMatch(Character::isLetterOrDigit);
    }

    /** Una palabra reconocida y su confianza (0-100; negativa si el lector no la puntuó). */
    public record Word(String text, int confidence) {

        public Word {
            text = text == null ? "" : text;
        }
    }
}
