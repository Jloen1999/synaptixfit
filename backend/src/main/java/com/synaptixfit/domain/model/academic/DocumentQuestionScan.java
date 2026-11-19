package com.synaptixfit.domain.model.academic;

import java.util.List;

/**
 * Preguntas que ya traía un apunte o archivo, en el orden del documento. {@code complete} es falso si una
 * tanda de la IA falló tras reintentarla o se llegó al tope: se devuelven las que se leyeron.
 */
public record DocumentQuestionScan(List<DocumentQuestion> questions, boolean complete) {

    /** Tope de preguntas que se leen de un documento: más ya no caben en una revisión cómoda. */
    public static final int MAX_QUESTIONS = 40;

    public DocumentQuestionScan {
        questions = List.copyOf(questions);
    }
}
