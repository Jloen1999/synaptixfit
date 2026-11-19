package com.synaptixfit.domain.model.academic;

import com.synaptixfit.domain.exception.DomainException;
import java.util.List;
import java.util.regex.Pattern;

/**
 * Pregunta que ya venía escrita en el apunte o archivo (ADR 0058). La IA la copia, no la inventa; si el
 * documento no traía la respuesta, la propone ({@link Status#ANSWER_PROPOSED}, «Revísala»). Las de
 * respuesta larga no se pueden corregir solas y no se usan.
 *
 * @param type nulo si es de respuesta larga
 */
public record DocumentQuestion(QuestionType type, String statement, List<String> options, List<String> answers,
                               String explanation, Status status) {

    /** Si se puede usar y por qué no. */
    public enum Status {
        /** Con la respuesta del propio documento. */
        READY,
        /** El documento no traía la respuesta: la propone la IA y se revisa antes de guardar. */
        ANSWER_PROPOSED,
        /** De desarrollo: no se puede corregir sola. */
        LONG_ANSWER,
        /** Sin respuesta válida (ni del documento ni propuesta). */
        NO_ANSWER
    }

    /**
     * Señales de que un texto trae preguntas escritas: signos de interrogación, huecos, «Pregunta 3»,
     * «Ejercicio 2» u opciones «a)». Sin ninguna no se llama a la IA (ahorra una llamada por apunte).
     */
    private static final Pattern QUESTION_HINT = Pattern.compile(
            "[?¿]|_{3,}|(?im)^\\s*(pregunta|ejercicio|cuesti[oó]n|question|exercise|exercice|quest[aã]o)\\b"
                    + "|(?m)^\\s*[a-dA-D][).]\\s");

    public DocumentQuestion {
        statement = statement == null ? "" : statement.strip();
        options = options == null ? List.of() : List.copyOf(options);
        answers = answers == null ? List.of() : List.copyOf(answers);
    }

    /**
     * Clasifica la pregunta que devuelve la IA: sin tipo es de respuesta larga; sin respuesta válida (vacía
     * o que no está entre las opciones) no se puede usar.
     */
    public static DocumentQuestion of(QuestionType type, String statement, List<String> options,
                                      List<String> answers, boolean answerFromDocument, String explanation) {
        if (type == null) {
            return new DocumentQuestion(null, statement, options, List.of(), null, Status.LONG_ANSWER);
        }
        try {
            QuestionDraft draft = draft(type, statement, options, answers, explanation);
            return new DocumentQuestion(type, draft.statement(), draft.options(), draft.correctAnswers(),
                    draft.explanation(), answerFromDocument ? Status.READY : Status.ANSWER_PROPOSED);
        } catch (DomainException e) {
            return new DocumentQuestion(type, statement, options, List.of(), explanation, Status.NO_ANSWER);
        }
    }

    /** Si merece la pena buscar preguntas en este texto (los archivos siempre se miran). */
    public static boolean mayContainQuestions(String text) {
        return text != null && QUESTION_HINT.matcher(text).find();
    }

    public boolean usable() {
        return status == Status.READY || status == Status.ANSWER_PROPOSED;
    }

    /** Pregunta lista para guardar (solo si se puede usar). */
    public QuestionDraft toDraft() {
        return draft(type, statement, options, answers, explanation);
    }

    private static QuestionDraft draft(QuestionType type, String statement, List<String> options,
                                       List<String> answers, String explanation) {
        List<String> given = answers == null ? List.of() : answers;
        return type == QuestionType.MULTIPLE_ANSWER
                ? QuestionDraft.multipleAnswer(statement, options, given, explanation)
                : new QuestionDraft(type, statement, options, given.isEmpty() ? null : given.getFirst(), explanation);
    }
}
