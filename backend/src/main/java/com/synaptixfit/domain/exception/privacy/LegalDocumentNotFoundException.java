package com.synaptixfit.domain.exception.privacy;

import com.synaptixfit.domain.exception.ResourceNotFoundException;

/** El texto legal pedido no existe (nombre desconocido en la URL). */
public class LegalDocumentNotFoundException extends ResourceNotFoundException {

    public LegalDocumentNotFoundException(String slug) {
        super("LEGAL_DOCUMENT_NOT_FOUND", "Legal document", slug);
    }
}
