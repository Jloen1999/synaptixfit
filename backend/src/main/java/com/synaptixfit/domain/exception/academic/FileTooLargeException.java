package com.synaptixfit.domain.exception.academic;

import com.synaptixfit.domain.exception.InvalidInputException;

/** El archivo supera el tamaño máximo permitido (25 MB). */
public class FileTooLargeException extends InvalidInputException {

    public FileTooLargeException(long sizeBytes, long maxBytes) {
        super("FILE_TOO_LARGE", "File size " + sizeBytes + " exceeds the maximum of " + maxBytes + " bytes");
    }
}
