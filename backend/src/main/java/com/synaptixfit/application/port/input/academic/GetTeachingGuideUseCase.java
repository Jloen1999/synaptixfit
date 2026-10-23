package com.synaptixfit.application.port.input.academic;

import com.synaptixfit.domain.model.academic.TeachingGuideDocument;
import java.util.UUID;

/** Guía docente guardada de una asignatura propia. */
public interface GetTeachingGuideUseCase {

    TeachingGuideDocument getTeachingGuide(UUID userId, UUID subjectId);
}
