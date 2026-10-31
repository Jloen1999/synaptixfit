package com.synaptixfit.domain.exception.profile;

import com.synaptixfit.domain.exception.InvalidInputException;

/** El documento de matrícula está vacío, no es un PDF o supera el tamaño máximo. */
public class EnrollmentFileInvalidException extends InvalidInputException {

    public EnrollmentFileInvalidException() {
        super("ENROLLMENT_FILE_INVALID", "The enrollment document must be a PDF of up to 5 MB");
    }
}
