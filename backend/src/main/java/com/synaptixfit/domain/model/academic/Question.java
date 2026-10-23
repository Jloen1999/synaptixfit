package com.synaptixfit.domain.model.academic;

import java.text.Normalizer;
import java.util.List;
import java.util.Locale;
import java.util.Objects;
import java.util.UUID;

/**
 * Pregunta de un banco. La corrección es tolerante: ignora mayúsculas, tildes, espacios
 * repetidos y la puntuación final (el sistema antiguo solo ignoraba mayúsculas).
 */
public record Question(UUID id, UUID bankId, QuestionType type, String statement, List<String> options,
                       String correctAnswer, String explanation, int order) {

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

    public boolean isCorrect(String answer) {
        return answer != null && normalize(answer).equals(normalize(correctAnswer));
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
