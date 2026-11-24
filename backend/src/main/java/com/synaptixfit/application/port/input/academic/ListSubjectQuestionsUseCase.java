package com.synaptixfit.application.port.input.academic;

import com.synaptixfit.domain.model.academic.QuestionType;
import com.synaptixfit.domain.model.academic.SubjectQuestions;
import java.util.Set;
import java.util.UUID;

/**
 * Todas las preguntas de una asignatura con cómo va cada una, para el apartado «Practicar» (ADR 0063). Solo
 * los tipos que la app sabe pintar (ADR 0058).
 */
public interface ListSubjectQuestionsUseCase {

    SubjectQuestions listSubjectQuestions(UUID userId, UUID subjectId, Set<QuestionType> visibleTypes);
}
