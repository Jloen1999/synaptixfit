package com.synaptixfit.domain.exception.profile;

import com.synaptixfit.domain.exception.BusinessRuleException;

/** Sin el permiso expreso del usuario no se lee un documento de matrícula (lleva datos personales). */
public class EnrollmentConsentRequiredException extends BusinessRuleException {

    public EnrollmentConsentRequiredException() {
        super("ENROLLMENT_CONSENT_REQUIRED", "Explicit consent is required to read an enrollment document");
    }
}
