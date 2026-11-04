package com.synaptixfit.domain.exception.training;

import com.synaptixfit.domain.exception.BusinessRuleException;

/** Para activar el seguimiento del ciclo hay que aceptar expresamente para qué se usan esos datos. */
public class CycleConsentRequiredException extends BusinessRuleException {

    public CycleConsentRequiredException() {
        super("CYCLE_CONSENT_REQUIRED", "Cycle tracking needs explicit consent");
    }
}
