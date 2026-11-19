package com.synaptixfit.domain.model.academic;

import com.synaptixfit.domain.exception.FieldValidationException;
import java.util.ArrayList;
import java.util.List;

/**
 * Una tanda de preguntas que se pide a la IA de una vez, con cuántas de cada formato. {@link #plan} reparte
 * las preguntas nuevas en tandas de {@link #SIZE} (ADR 0058).
 */
public record QuestionBatch(int singleChoice, int multipleAnswer, int fillInBlank, int flashcards) {

    /**
     * Preguntas por tanda. Diez preguntas ocupan unos 2.000 tokens de salida, lejos del tope de la IA
     * (8.192, DEEPSEEK_MAX_TOKENS): una tanda de 30 se acercaba y, cortada, el JSON ya no sirve. Además, si
     * una tanda falla solo se repite esa.
     */
    public static final int SIZE = 10;

    /** Máximo de preguntas nuevas por petición (la hoja ofrece de 5 a 30). */
    public static final int MAX_NEW_QUESTIONS = 30;

    public int total() {
        return singleChoice + multipleAnswer + fillInBlank + flashcards;
    }

    /**
     * Reparte {@code count} preguntas del formato pedido en tandas. En la mezcla se alternan elegir una,
     * completar la frase y (si la app la sabe pintar) varias correctas, para que cada tanda sea variada.
     */
    public static List<QuestionBatch> plan(QuestionFormat format, int count, boolean multipleAnswerAllowed) {
        if (count < 0 || count > MAX_NEW_QUESTIONS) {
            throw new FieldValidationException("newQuestions", "OUT_OF_RANGE",
                    "newQuestions must be between 0 and " + MAX_NEW_QUESTIONS);
        }
        QuestionFormat chosen = format == null ? QuestionFormat.MIXED : format;
        if (chosen == QuestionFormat.MULTIPLE_ANSWER && !multipleAnswerAllowed) {
            chosen = QuestionFormat.SINGLE_CHOICE;
        }
        List<QuestionFormat> cycle = chosen != QuestionFormat.MIXED ? List.of(chosen)
                : multipleAnswerAllowed
                ? List.of(QuestionFormat.SINGLE_CHOICE, QuestionFormat.FILL_IN_BLANK, QuestionFormat.MULTIPLE_ANSWER)
                : List.of(QuestionFormat.SINGLE_CHOICE, QuestionFormat.FILL_IN_BLANK);
        List<QuestionBatch> batches = new ArrayList<>();
        int[] counts = new int[4];
        int inBatch = 0;
        for (int i = 0; i < count; i++) {
            counts[cycle.get(i % cycle.size()).ordinal()]++;
            if (++inBatch == SIZE || i == count - 1) {
                batches.add(new QuestionBatch(counts[QuestionFormat.SINGLE_CHOICE.ordinal()],
                        counts[QuestionFormat.MULTIPLE_ANSWER.ordinal()], counts[QuestionFormat.FILL_IN_BLANK.ordinal()],
                        counts[QuestionFormat.FLASHCARD.ordinal()]));
                counts = new int[4];
                inBatch = 0;
            }
        }
        return List.copyOf(batches);
    }
}
