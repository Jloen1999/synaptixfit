package com.synaptixfit.domain.exception.academic;

import com.synaptixfit.domain.exception.ConflictException;

/** La subida ya se confirmó antes (clave de objeto duplicada). */
public class FileAlreadyRegisteredException extends ConflictException {

    public FileAlreadyRegisteredException(String objectKey) {
        super("FILE_ALREADY_REGISTERED", "File already registered: " + objectKey);
    }
}
