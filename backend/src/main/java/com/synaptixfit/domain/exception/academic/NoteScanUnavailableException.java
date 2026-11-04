package com.synaptixfit.domain.exception.academic;

import com.synaptixfit.domain.exception.ExternalServiceException;

/** El lector de texto de imágenes (OCR) no está instalado, está ocupado o ha fallado. */
public class NoteScanUnavailableException extends ExternalServiceException {

    public NoteScanUnavailableException(String message) {
        super("NOTE_SCAN_UNAVAILABLE", message);
    }
}
