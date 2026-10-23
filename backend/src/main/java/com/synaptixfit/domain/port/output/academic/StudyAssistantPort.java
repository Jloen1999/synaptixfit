package com.synaptixfit.domain.port.output.academic;

import com.synaptixfit.domain.model.academic.MindMap;
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

    Summary summarize(List<Source> sources);

    GeneratedMindMap mindMap(List<Source> sources);

    Flashcards flashcards(List<Source> sources);

    /** 10 preguntas: 5 de opción múltiple (4 opciones) y 5 de rellenar hueco. */
    PracticeQuestions practiceQuestions(List<Source> sources);

    TeachingGuide extractTeachingGuide(Source document);
}
