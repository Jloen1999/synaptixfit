package com.synaptixfit.domain.port.output.academic;

import com.synaptixfit.domain.model.academic.DocumentQuestion;
import com.synaptixfit.domain.model.academic.MindMap;
import com.synaptixfit.domain.model.academic.QuestionBatch;
import com.synaptixfit.domain.model.academic.QuestionDraft;
import com.synaptixfit.domain.model.academic.TeachingGuide;
import java.util.List;

/**
 * Asistente de estudio con IA. Recibe una o varias fuentes (texto de apuntes o binarios PDF o
 * imagen) y las sintetiza de forma integrada. Lanza AiUnavailableException si la respuesta no
 * es utilizable y AiQuotaExceededException si se agota la cuota.
 */
public interface StudyAssistantPort {

    /** Fuente: {@code text} para apuntes o {@code mimeType} y {@code data} para archivos. */
    record Source(String title, String text, String mimeType, byte[] data) {

        public static Source text(String title, String text) {
            return new Source(title, text, null, null);
        }

        public static Source binary(String title, String mimeType, byte[] data) {
            return new Source(title, null, mimeType, data);
        }

        public boolean isBinary() {
            return data != null;
        }
    }

    record Summary(String title, String markdown) {
    }

    record GeneratedMindMap(String title, MindMap mindMap) {
    }

    record Flashcard(String question, String answer) {
    }

    record Flashcards(String title, List<Flashcard> cards) {
    }

    record PracticeQuestions(String title, List<QuestionDraft> questions) {
    }

    /** Tanda de preguntas ya escritas en un documento y cuántas tiene en total. */
    record DocumentQuestionPage(int total, List<DocumentQuestion> questions) {
    }

    Summary summarize(List<Source> sources);

    GeneratedMindMap mindMap(List<Source> sources);

    Flashcards flashcards(List<Source> sources);

    /** 10 preguntas: 5 de opción múltiple (4 opciones) y 5 de rellenar hueco. */
    PracticeQuestions practiceQuestions(List<Source> sources);

    /**
     * Una tanda de «Crear preguntas» (ADR 0058) con los formatos de {@code batch}, sin repetir los
     * enunciados de {@code avoid} (las que ya tienes y las de tandas anteriores).
     */
    PracticeQuestions practiceQuestions(List<Source> sources, QuestionBatch batch, List<String> avoid);

    /**
     * Preguntas que ya están escritas en el documento, en su orden, desde la posición {@code from} (base 0)
     * y como mucho {@code limit}. La IA las copia, no las inventa.
     */
    DocumentQuestionPage documentQuestions(Source source, int from, int limit);

    TeachingGuide extractTeachingGuide(Source document);
}
