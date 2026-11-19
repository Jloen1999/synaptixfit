package com.synaptixfit.domain.model.academic;

import java.text.Normalizer;
import java.util.Arrays;
import java.util.List;
import java.util.Locale;
import java.util.Objects;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Pregunta de un banco. La corrección es tolerante: ignora mayúsculas, tildes, espacios
 * repetidos y la puntuación final (el sistema antiguo solo ignoraba mayúsculas).
 *
 * <p>En «Varias correctas» ({@link QuestionType#MULTIPLE_ANSWER}) {@code correctAnswer} guarda las opciones
 * correctas separadas por {@link #ANSWER_SEPARATOR} (las opciones nunca llevan saltos de línea, ver
 * {@link QuestionDraft}); la respuesta dada se guarda igual. Puntúa todo o nada (ADR 0058).
 */
public record Question(UUID id, UUID bankId, QuestionType type, String statement, List<String> options,
                       String correctAnswer, String explanation, int order) {

    /** Separa las opciones elegidas o correctas de una pregunta de varias correctas. */
    public static final String ANSWER_SEPARATOR = "\n";

    public Question {
        Objects.requireNonNull(id, "id");
        Objects.requireNonNull(bankId, "bankId");
        Objects.requireNonNull(type, "type");
        options = options == null ? List.of() : List.copyOf(options);
    }

    public static Question from(QuestionDraft draft, UUID bankId, int order) {
        return new Question(UUID.randomUUID(), bankId, draft.type(), draft.statement(), draft.options(),
                draft.correctAnswer(), draft.explanation(), order);
    }

    /** Respuestas correctas: una sola salvo en «Varias correctas». */
    public List<String> correctAnswers() {
        return type == QuestionType.MULTIPLE_ANSWER ? splitAnswers(correctAnswer) : List.of(correctAnswer);
    }

    /**
     * Si la respuesta es correcta. En «Varias correctas» cuenta solo si se marcan todas las correctas y
     * ninguna incorrecta: el conjunto elegido es igual al correcto (todo o nada, decisión del usuario; sin
     * puntos parciales, porque marcarlo todo sería una estrategia ganadora). Ver formulas.md.
     */
    public boolean isCorrect(String answer) {
        if (answer == null) {
            return false;
        }
        if (type == QuestionType.MULTIPLE_ANSWER) {
            Set<String> given = normalizedSet(splitAnswers(answer));
            return !given.isEmpty() && given.equals(normalizedSet(correctAnswers()));
        }
        return normalize(answer).equals(normalize(correctAnswer));
    }

    /** Une varias respuestas para guardarlas o corregirlas; descarta las vacías. */
    public static String joinAnswers(List<String> answers) {
        return answers == null ? "" : answers.stream().filter(a -> a != null && !a.isBlank())
                .map(a -> a.strip().replaceAll("\\s+", " ")).collect(Collectors.joining(ANSWER_SEPARATOR));
    }

    /** Separa las respuestas unidas con {@link #joinAnswers(List)}. */
    public static List<String> splitAnswers(String joined) {
        if (joined == null || joined.isBlank()) {
            return List.of();
        }
        return Arrays.stream(joined.split(ANSWER_SEPARATOR)).map(String::strip).filter(s -> !s.isEmpty()).toList();
    }

    private static Set<String> normalizedSet(List<String> answers) {
        return answers.stream().map(Question::normalize).collect(Collectors.toSet());
    }

    static String normalize(String text) {
        String n = Normalizer.normalize(text == null ? "" : text, Normalizer.Form.NFD)
                .replaceAll("\\p{M}+", "")
                .toLowerCase(Locale.ROOT)
                .replaceAll("\\s+", " ")
                .strip();
        return n.replaceAll("[.,;:!?¡¿]+$", "").strip();
    }
}
