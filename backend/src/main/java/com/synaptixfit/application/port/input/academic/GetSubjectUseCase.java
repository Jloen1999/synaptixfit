package com.synaptixfit.application.port.input.academic;

import com.synaptixfit.domain.model.academic.SubjectSummary;
import java.util.UUID;

/** Detalle de una asignatura propia con sus conteos. */
public interface GetSubjectUseCase {

    /** {@code zone}: zona IANA del móvil para contar los días de la agenda; nula, la del servidor. */
    SubjectSummary getSubject(UUID userId, UUID subjectId, String zone);
}
