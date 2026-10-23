package com.synaptixfit.application.port.input.academic;

import com.synaptixfit.domain.model.academic.Subject;
import com.synaptixfit.domain.model.academic.SubjectPriority;
import java.time.Instant;
import java.util.UUID;

/** Crea una asignatura propia. Los campos nulos toman su valor por defecto. */
public interface CreateSubjectUseCase {

    record Command(UUID userId, String name, String code, String description, Integer credits,
                   Integer perceivedDifficulty, SubjectPriority priority, Instant nextAssessmentAt, String teacher,
                   String icsUrl) {}

    Subject createSubject(Command command);
}
