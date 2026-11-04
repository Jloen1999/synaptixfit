package com.synaptixfit.application.port.input.academic;

import com.synaptixfit.domain.model.academic.MockExamOptions;
import java.util.UUID;

/** Materiales de una asignatura que pueden entrar en un simulacro (los que tienen preguntas). */
public interface GetMockExamOptionsUseCase {

    MockExamOptions getMockExamOptions(UUID userId, UUID subjectId);
}
