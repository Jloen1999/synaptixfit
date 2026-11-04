package com.synaptixfit.application.service.training;

import com.synaptixfit.application.port.input.training.GetHealthConsentUseCase;
import com.synaptixfit.application.port.input.training.GiveHealthConsentUseCase;
import com.synaptixfit.application.port.input.training.WithdrawHealthConsentUseCase;
import com.synaptixfit.domain.model.training.HealthConsent;
import com.synaptixfit.domain.port.output.training.DailyCheckInRepositoryPort;
import com.synaptixfit.domain.port.output.training.HealthConsentRepositoryPort;

import java.time.Clock;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.Optional;
import java.util.UUID;

/**
 * Consentimiento para el registro diario (ADR 0034): darlo, consultarlo y retirarlo. Al retirarlo se borra el
 * registro de hoy (es el único que usan la adaptación de la sesión y la generación de rutinas) y, si se pide,
 * todos los anteriores.
 */
public class HealthConsentService implements GetHealthConsentUseCase, GiveHealthConsentUseCase,
        WithdrawHealthConsentUseCase {

    private final HealthConsentRepositoryPort consents;
    private final DailyCheckInRepositoryPort checkIns;
    private final Clock clock;
    private final ZoneId zone;

    public HealthConsentService(HealthConsentRepositoryPort consents, DailyCheckInRepositoryPort checkIns, Clock clock,
                                ZoneId zone) {
        this.consents = consents;
        this.checkIns = checkIns;
        this.clock = clock;
        this.zone = zone;
    }

    @Override
    public Status getHealthConsent(UUID userId) {
        Optional<HealthConsent> consent = consents.find(userId);
        return new Status(consent.map(HealthConsent::active).orElse(false),
                consent.map(HealthConsent::givenAt).orElse(null),
                consent.map(HealthConsent::withdrawnAt).orElse(null));
    }

    @Override
    public void giveHealthConsent(UUID userId) {
        boolean active = consents.find(userId).map(HealthConsent::active).orElse(false);
        if (!active) {
            consents.save(HealthConsent.give(userId, clock.instant()));
        }
    }

    @Override
    public void withdrawHealthConsent(UUID userId, boolean deleteRecords) {
        consents.find(userId).filter(HealthConsent::active)
                .ifPresent(c -> consents.save(c.withdraw(clock.instant())));
        if (deleteRecords) {
            checkIns.deleteByUser(userId);
        } else {
            checkIns.deleteByUserAndDate(userId, LocalDate.ofInstant(clock.instant(), zone));
        }
    }
}
