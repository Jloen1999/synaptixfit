package com.synaptixfit.domain.exception.academic;

import com.synaptixfit.domain.exception.ResourceNotFoundException;

/** La asignatura no tiene curso y semestre asignados. */
public class SubjectSemesterNotFoundException extends ResourceNotFoundException {

    public SubjectSemesterNotFoundException(Object id) {
        super("SUBJECT_SEMESTER_NOT_FOUND", "Subject semester", id);
    }
}
