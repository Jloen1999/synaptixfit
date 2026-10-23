package com.synaptixfit.application.port.input.academic;

import java.util.UUID;

/** Quita la asignación de curso y semestre de una asignatura propia. */
public interface RemoveSubjectSemesterUseCase {

    void removeSemester(UUID userId, UUID subjectId);
}
