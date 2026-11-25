package com.synaptixfit.domain.exception.academic;

import com.synaptixfit.domain.exception.ExternalServiceException;

/** No se ha podido crear el PDF de un apunte (fallo del generador, ADR 0064): se reintenta más tarde. */
public class NotePdfUnavailableException extends ExternalServiceException {

    public NotePdfUnavailableException(String detail) {
        super("NOTE_PDF_UNAVAILABLE", "could not render the note as PDF: " + detail);
    }
}
