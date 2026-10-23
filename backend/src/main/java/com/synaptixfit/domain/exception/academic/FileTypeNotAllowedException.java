package com.synaptixfit.domain.exception.academic;

import com.synaptixfit.domain.exception.InvalidInputException;

/** Tipo de archivo no permitido para las asignaturas. */
public class FileTypeNotAllowedException extends InvalidInputException {

    public FileTypeNotAllowedException(String mimeType) {
        super("FILE_TYPE_NOT_ALLOWED", "File type not allowed: " + mimeType);
    }
}
