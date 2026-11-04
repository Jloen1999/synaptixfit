package com.synaptixfit.application.port.input.training;

import java.util.UUID;

/**
 * Retira el consentimiento del registro diario. El de hoy se borra siempre (dejaría de adaptarse el entreno con
 * él); con {@code deleteRecords} se borran también los anteriores.
 */
public interface WithdrawHealthConsentUseCase {

    void withdrawHealthConsent(UUID userId, boolean deleteRecords);
}
