package com.synaptixfit.application.port.input.academic;

import com.synaptixfit.domain.model.academic.SubjectPriority;
import com.synaptixfit.domain.model.academic.SubjectSummary;
import java.time.Instant;
import java.util.UUID;

/** Edita una asignatura (los campos nulos no cambian; un texto en blanco borra el valor) o la archiva. */
public interface UpdateSubjectUseCase {

    record Command(UUID userId, UUID subjectId, String name, String code, String description, Integer credits,
                   Integer perceivedDifficulty, SubjectPriority priority, Instant nextAssessmentAt,
                   boolean clearNextAssessment, String teacher, String icsUrl, Boolean archived, String room) {

        public Command(UUID userId, UUID subjectId, String name, String code, String description, Integer credits,
                       Integer perceivedDifficulty, SubjectPriority priority, Instant nextAssessmentAt,
                       boolean clearNextAssessment, String teacher, String icsUrl, Boolean archived) {
            this(userId, subjectId, name, code, description, credits, perceivedDifficulty, priority,
                    nextAssessmentAt, clearNextAssessment, teacher, icsUrl, archived, null);
        }
    }

    SubjectSummary updateSubject(Command command);
}
