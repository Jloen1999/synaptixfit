package com.synaptixfit.domain.exception.academic;

import com.synaptixfit.domain.exception.BusinessRuleException;

/** La IA no encontró profesorado, temario, evaluación ni bibliografía en el documento. */
public class TeachingGuideEmptyException extends BusinessRuleException {

    public TeachingGuideEmptyException(Object fileId) {
        super("STUDY_GUIDE_EMPTY", "No teaching guide data found in file " + fileId);
    }
}
