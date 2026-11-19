package com.synaptixfit.domain.model.academic;

import com.synaptixfit.domain.exception.FieldValidationException;
import com.synaptixfit.domain.model.shared.Guard;
import java.util.ArrayList;
import java.util.Collection;
import java.util.List;

/**
 * Pregunta aún no guardada (generada por la IA, sacada del documento o enviada por el cliente). Las de
 * opciones necesitan al menos dos; en «Elegir una» la respuesta es una de ellas y en «Varias correctas»
 * todas sus respuestas lo son (se guardan con el texto exacto de la opción y en su orden).
 */
public record QuestionDraft(QuestionType type, String statement, List<String> options, String correctAnswer,
                            String explanation) {

    public QuestionDraft {
        type = type == null ? QuestionType.MULTIPLE_CHOICE : type;
        statement = Guard.length(statement, "statement", 1, 2000);
        // Cada opción en una sola línea: el salto de línea separa las respuestas de «Varias correctas».
        options = options == null ? List.of()
                : options.stream().filter(o -> o != null && !o.isBlank())
                        .map(o -> o.strip().replaceAll("\\s+", " ")).toList();
        explanation = explanation == null || explanation.isBlank() ? null : explanation.strip();
        switch (type) {
            case MULTIPLE_CHOICE -> {
                correctAnswer = Guard.length(correctAnswer, "correctAnswer", 1, 1000);
                requireOptions(options);
                String answer = correctAnswer;
                if (options.stream().noneMatch(o -> same(o, answer))) {
                    throw new FieldValidationException("correctAnswer", "INVALID",
                            "the correct answer must be one of the options");
                }
            }
            case MULTIPLE_ANSWER -> {
                requireOptions(options);
                correctAnswer = canonicalAnswers(options, Question.splitAnswers(correctAnswer));
            }
            case FILL_IN_BLANK -> {
                correctAnswer = Guard.length(correctAnswer, "correctAnswer", 1, 1000);
                options = List.of();
            }
        }
    }

    /** «Varias correctas» con sus respuestas como lista. */
    public static QuestionDraft multipleAnswer(String statement, List<String> options, List<String> correct,
                                               String explanation) {
        return new QuestionDraft(QuestionType.MULTIPLE_ANSWER, statement, options, Question.joinAnswers(correct),
                explanation);
    }

    /** Respuestas correctas: una sola salvo en «Varias correctas». */
    public List<String> correctAnswers() {
        return type == QuestionType.MULTIPLE_ANSWER ? Question.splitAnswers(correctAnswer) : List.of(correctAnswer);
    }

    /** Misma pregunta (enunciado igual sin contar mayúsculas, tildes ni espacios): no se guarda dos veces. */
    public boolean sameStatement(String other) {
        return same(statement, other);
    }

    /**
     * Las preguntas cuyo enunciado no está ya en {@code existing} ni repetido entre ellas, en su orden: al
     * añadir preguntas a un banco no se guarda dos veces la misma (ADR 0058).
     */
    public static List<QuestionDraft> withoutRepeats(Collection<String> existing, List<QuestionDraft> drafts) {
        List<String> seen = new ArrayList<>(existing == null ? List.of() : existing);
        List<QuestionDraft> kept = new ArrayList<>();
        for (QuestionDraft d : drafts == null ? List.<QuestionDraft>of() : drafts) {
            if (seen.stream().noneMatch(d::sameStatement)) {
                kept.add(d);
                seen.add(d.statement());
            }
        }
        return List.copyOf(kept);
    }

    private static void requireOptions(List<String> options) {
        if (options.size() < 2) {
            throw new FieldValidationException("options", "INVALID_LENGTH",
                    "choice questions need at least two options");
        }
    }

    /** Las correctas con el texto de su opción y en el orden de las opciones; todas deben existir. */
    private static String canonicalAnswers(List<String> options, List<String> given) {
        if (given.isEmpty()) {
            throw new FieldValidationException("correctAnswer", "REQUIRED", "at least one correct answer is required");
        }
        for (String g : given) {
            if (options.stream().noneMatch(o -> same(o, g))) {
                throw new FieldValidationException("correctAnswer", "INVALID",
                        "every correct answer must be one of the options");
            }
        }
        List<String> canonical = new ArrayList<>();
        for (String o : options) {
            if (given.stream().anyMatch(g -> same(o, g)) && canonical.stream().noneMatch(c -> same(c, o))) {
                canonical.add(o);
            }
        }
        return Guard.length(Question.joinAnswers(canonical), "correctAnswer", 1, 4000);
    }

    private static boolean same(String a, String b) {
        return Question.normalize(a).equals(Question.normalize(b));
    }
}
