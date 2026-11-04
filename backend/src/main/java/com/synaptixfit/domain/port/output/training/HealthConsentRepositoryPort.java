package com.synaptixfit.domain.port.output.training;

import com.synaptixfit.domain.model.training.HealthConsent;

import java.util.Optional;
import java.util.UUID;

/** Persistencia del consentimiento para el registro diario (ADR 0034). */
public interface HealthConsentRepositoryPort {

    Optional<HealthConsent> find(UUID userId);

    void save(HealthConsent consent);
}
