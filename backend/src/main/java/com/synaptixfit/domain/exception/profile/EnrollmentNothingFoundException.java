package com.synaptixfit.domain.exception.profile;

import com.synaptixfit.domain.exception.BusinessRuleException;

/** No se ha encontrado ninguna asignatura matriculada en el documento. */
public class EnrollmentNothingFoundException extends BusinessRuleException {

    public EnrollmentNothingFoundException() {
        super("ENROLLMENT_NOTHING_FOUND", "No enrolled subjects were found in the document");
    }
}
