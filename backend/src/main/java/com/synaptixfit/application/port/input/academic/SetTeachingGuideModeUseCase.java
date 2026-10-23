package com.synaptixfit.application.port.input.academic;

import com.synaptixfit.domain.model.academic.TeachingGuide.EvaluationMode;
import com.synaptixfit.domain.model.academic.TeachingGuideDocument;
import java.util.UUID;

/** Elige la modalidad de evaluación (continua o global) con la que se calcula la nota. */
public interface SetTeachingGuideModeUseCase {

    TeachingGuideDocument setMode(UUID userId, UUID subjectId, EvaluationMode mode);
}
