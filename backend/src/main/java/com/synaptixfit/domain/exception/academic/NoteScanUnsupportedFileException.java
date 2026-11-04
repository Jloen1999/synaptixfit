package com.synaptixfit.domain.exception.academic;

import com.synaptixfit.domain.exception.InvalidInputException;

/** Las fotos de apuntes deben ser de 1 a 5 imágenes JPG, PNG o WEBP que se puedan abrir. */
public class NoteScanUnsupportedFileException extends InvalidInputException {

    public NoteScanUnsupportedFileException() {
        super("NOTE_SCAN_UNSUPPORTED_FILE", "Send between 1 and 5 JPG, PNG or WEBP photos");
    }
}
