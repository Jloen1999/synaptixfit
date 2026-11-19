package com.synaptixfit.domain.model.academic;

/**
 * Qué preguntas pide la persona en «Crear preguntas» (ADR 0058). «Tarjetas» se guardan como preguntas de
 * respuesta corta ({@link QuestionType#FILL_IN_BLANK}): pregunta directa y respuesta de pocas palabras, que
 * es lo que pinta el modo Tarjetas. «Mezcla» reparte entre elegir una, completar la frase y varias correctas.
 */
public enum QuestionFormat {
    SINGLE_CHOICE,
    MULTIPLE_ANSWER,
    FILL_IN_BLANK,
    FLASHCARD,
    MIXED;

    /** Tipo con el que se guarda una pregunta de este formato (no aplica a {@link #MIXED}). */
    public QuestionType storedAs() {
        return switch (this) {
            case SINGLE_CHOICE, MIXED -> QuestionType.MULTIPLE_CHOICE;
            case MULTIPLE_ANSWER -> QuestionType.MULTIPLE_ANSWER;
            case FILL_IN_BLANK, FLASHCARD -> QuestionType.FILL_IN_BLANK;
        };
    }
}
