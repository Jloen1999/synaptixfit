package com.synaptixfit.application.port.input.academic;

import com.synaptixfit.domain.model.academic.TeachingGuideDocument;
import java.util.UUID;

/** Anota (o borra, con null) la nota de un criterio de evaluación para la calculadora. */
public interface GradeTeachingGuideAssessmentUseCase {

    TeachingGuideDocument setAssessmentGrade(UUID userId, UUID subjectId, int assessmentIndex, Double grade);
}
