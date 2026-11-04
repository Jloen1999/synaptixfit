package com.synaptixfit.domain.exception.training;

import com.synaptixfit.domain.exception.BusinessRuleException;

/** El registro diario guarda datos de salud: antes hay que dar el consentimiento expreso (ADR 0034). */
public class HealthConsentRequiredException extends BusinessRuleException {

    public HealthConsentRequiredException() {
        super("HEALTH_CONSENT_REQUIRED", "The daily check-in needs explicit health-data consent");
    }
}
