package com.synaptixfit.application.service.academic;

import com.synaptixfit.domain.exception.AiQuotaExceededException;
import com.synaptixfit.domain.exception.AiUnavailableException;
import com.synaptixfit.domain.model.academic.DocumentQuestion;
import com.synaptixfit.domain.model.academic.DocumentQuestionScan;
import com.synaptixfit.domain.model.academic.QuestionBatch;
import com.synaptixfit.domain.port.output.academic.StudyAssistantPort;
import java.util.ArrayList;
import java.util.List;

/**
 * Lee con {@link StudyAssistantPort} las preguntas ya escritas en un documento, por tandas de
 * {@link QuestionBatch#SIZE} (ADR 0058). Si una tanda falla tras reintentarla, devuelve las leídas y marca
 * el resultado como incompleto; solo falla si no se leyó ninguna.
 */
final class DocumentQuestionScanner {

    private final StudyAssistantPort assistant;

    DocumentQuestionScanner(StudyAssistantPort assistant) {
        this.assistant = assistant;
    }

    DocumentQuestionScan scan(StudyAssistantPort.Source source) {
        if (!source.isBinary() && !DocumentQuestion.mayContainQuestions(source.text())) {
            return new DocumentQuestionScan(List.of(), true);
        }
        List<DocumentQuestion> found = new ArrayList<>();
        int total = DocumentQuestionScan.MAX_QUESTIONS;
        boolean complete = true;
        while (found.size() < Math.min(total, DocumentQuestionScan.MAX_QUESTIONS)) {
            int from = found.size();
            StudyAssistantPort.DocumentQuestionPage page;
            try {
                page = AiBatches.withRetry(() -> assistant.documentQuestions(source, from, QuestionBatch.SIZE));
            } catch (AiUnavailableException | AiQuotaExceededException e) {
                if (found.isEmpty()) {
                    throw e;
                }
                complete = false;
                break;
            }
            total = Math.max(0, page.total());
            if (page.questions().isEmpty()) {
                complete = found.size() >= total;
                break;
            }
            int room = Math.min(total, DocumentQuestionScan.MAX_QUESTIONS) - found.size();
            found.addAll(page.questions().subList(0, Math.min(room, page.questions().size())));
        }
        if (total > DocumentQuestionScan.MAX_QUESTIONS) {
            complete = false;
        }
        return new DocumentQuestionScan(found, complete);
    }
}
