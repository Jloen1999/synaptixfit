package com.synaptixfit.domain.model.academic;

import com.synaptixfit.domain.exception.FieldValidationException;
import com.synaptixfit.domain.model.shared.Guard;
import java.util.List;

/**
 * Pregunta aún no guardada (generada por la IA o enviada por el cliente). Las de opción
 * múltiple necesitan al menos dos opciones y la respuesta correcta debe ser una de ellas.
 */
public record QuestionDraft(QuestionType type, String statement, List<String> options, String correctAnswer,
                            String explanation) {

    public QuestionDraft {
        type = type == null ? QuestionType.MULTIPLE_CHOICE : type;
        statement = Guard.length(statement, "statement", 1, 2000);
        correctAnswer = Guard.length(correctAnswer, "correctAnswer", 1, 1000);
        options = options == null ? List.of()
                : options.stream().filter(o -> o != null && !o.isBlank()).map(String::strip).toList();
        explanation = explanation == null || explanation.isBlank() ? null : explanation.strip();
        if (type == QuestionType.MULTIPLE_CHOICE) {
            if (options.size() < 2) {
                throw new FieldValidationException("options", "INVALID_LENGTH",
                        "multiple choice questions need at least two options");
            }
            String answer = correctAnswer;
            if (options.stream().noneMatch(o -> Question.normalize(o).equals(Question.normalize(answer)))) {
                throw new FieldValidationException("correctAnswer", "INVALID",
                        "the correct answer must be one of the options");
            }
        } else {
            options = List.of();
        }
    }
}
