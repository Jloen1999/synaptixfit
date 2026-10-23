package com.synaptixfit.domain.exception.academic;

import com.synaptixfit.domain.exception.InvalidInputException;

/** La clave de objeto confirmada no corresponde a una subida del usuario para esa asignatura. */
public class InvalidFileUploadException extends InvalidInputException {

    public InvalidFileUploadException(String objectKey) {
        super("FILE_UPLOAD_INVALID", "Invalid upload object key: " + objectKey);
    }
}
