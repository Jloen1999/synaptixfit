package com.synaptixfit.domain.exception.academic;

import com.synaptixfit.domain.exception.ResourceNotFoundException;

/** No hay documento de IA guardado para esa fuente y tipo. */
public class AiDocumentNotFoundException extends ResourceNotFoundException {

    public AiDocumentNotFoundException(Object id) {
        super("STUDY_DOCUMENT_NOT_FOUND", "Study document", id);
    }
}
