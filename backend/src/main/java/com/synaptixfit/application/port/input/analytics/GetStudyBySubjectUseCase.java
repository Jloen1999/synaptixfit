package com.synaptixfit.application.port.input.analytics;

import com.synaptixfit.domain.model.analytics.StudyBySubject;
import java.util.UUID;

/** Horas de estudio por asignatura en las últimas semanas y cómo van sus repasos. */
public interface GetStudyBySubjectUseCase {

    int DEFAULT_WEEKS = 4;
    int MAX_WEEKS = 12;

    StudyBySubject getStudyBySubject(UUID userId, int weeks, String timeZone);
}
