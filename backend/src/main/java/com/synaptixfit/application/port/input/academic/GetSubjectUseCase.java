package com.synaptixfit.application.port.input.academic;

import com.synaptixfit.domain.model.academic.SubjectSummary;
import java.util.UUID;

/** Detalle de una asignatura propia con sus conteos. */
public interface GetSubjectUseCase {

    SubjectSummary getSubject(UUID userId, UUID subjectId);
}
