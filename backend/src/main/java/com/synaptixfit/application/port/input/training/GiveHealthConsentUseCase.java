package com.synaptixfit.application.port.input.training;

import java.util.UUID;

/** Da el consentimiento expreso para guardar el registro diario (datos de salud). */
public interface GiveHealthConsentUseCase {

    void giveHealthConsent(UUID userId);
}
