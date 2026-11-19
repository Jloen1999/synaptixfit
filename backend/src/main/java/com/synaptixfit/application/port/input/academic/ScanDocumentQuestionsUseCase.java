package com.synaptixfit.application.port.input.academic;

import com.synaptixfit.domain.model.academic.DocumentQuestionScan;
import java.util.UUID;

/**
 * Busca con IA las preguntas que ya trae escritas el apunte o archivo de un material, para revisarlas antes
 * de guardarlas (ADR 0058). No guarda nada.
 */
public interface ScanDocumentQuestionsUseCase {

    DocumentQuestionScan scanDocumentQuestions(UUID userId, UUID materialId);
}
