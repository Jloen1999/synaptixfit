package com.synaptixfit.domain.model.academic;

import java.util.UUID;

/**
 * Documento de IA guardado y ya interpretado: Markdown para el resumen, árbol para el mapa
 * mental y banco de preguntas para la práctica.
 */
public record StudyDocument(AiDocument document, String markdown, MindMap mindMap, UUID materialId,
                            UUID questionBankId, Integer questionCount) {
}
