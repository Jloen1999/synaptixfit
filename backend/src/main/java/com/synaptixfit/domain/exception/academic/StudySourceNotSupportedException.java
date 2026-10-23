package com.synaptixfit.domain.exception.academic;

import com.synaptixfit.domain.exception.BusinessRuleException;

/** La IA solo puede leer apuntes, PDF e imágenes. */
public class StudySourceNotSupportedException extends BusinessRuleException {

    public StudySourceNotSupportedException(String mimeType) {
        super("STUDY_SOURCE_NOT_SUPPORTED", "Unsupported study source type: " + mimeType);
    }
}
