package com.synaptixfit.domain.exception.academic;

import com.synaptixfit.domain.exception.BusinessRuleException;

/** Un apunte sin asignatura no puede ser material de estudio ni banco de preguntas. */
public class StudySourceWithoutSubjectException extends BusinessRuleException {

    public StudySourceWithoutSubjectException(Object noteId) {
        super("STUDY_SOURCE_WITHOUT_SUBJECT", "Note " + noteId + " has no subject");
    }
}
