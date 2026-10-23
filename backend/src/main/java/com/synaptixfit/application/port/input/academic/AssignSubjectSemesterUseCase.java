package com.synaptixfit.application.port.input.academic;

import com.synaptixfit.domain.model.academic.SubjectSemester;
import java.util.UUID;

/** Asigna (o cambia) el curso y semestre de una asignatura propia. */
public interface AssignSubjectSemesterUseCase {

    SubjectSemester assignSemester(UUID userId, UUID subjectId, int course, int semester);
}
