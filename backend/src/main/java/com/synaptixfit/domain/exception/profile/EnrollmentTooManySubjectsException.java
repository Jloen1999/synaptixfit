package com.synaptixfit.domain.exception.profile;

import com.synaptixfit.domain.exception.InvalidInputException;

/** Se piden más asignaturas de las que caben en una matrícula. */
public class EnrollmentTooManySubjectsException extends InvalidInputException {

    public EnrollmentTooManySubjectsException() {
        super("ENROLLMENT_TOO_MANY_SUBJECTS", "Too many subjects selected from the enrollment");
    }
}
