package com.synaptixfit.application.service.training;

import static org.assertj.core.api.Assertions.assertThat;

import com.synaptixfit.domain.model.training.DailyCheckIn;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** Consentimiento del registro diario (ADR 0034): darlo, retirarlo y qué se borra al retirarlo. */
class HealthConsentServiceTest {

    private static final UUID USER = UUID.randomUUID();
    private static final Instant NOW = Instant.parse("2026-11-04T10:00:00Z");
    private static final LocalDate TODAY = LocalDate.parse("2026-11-04");

    private final TrainingFakes.HealthConsents consents = new TrainingFakes.HealthConsents();
    private final TrainingFakes.CheckIns checkIns = new TrainingFakes.CheckIns();
    private final HealthConsentService service = new HealthConsentService(consents, checkIns,
            Clock.fixed(NOW, ZoneOffset.UTC), ZoneOffset.UTC);

    @Test
    void givingTwiceKeepsTheFirstDate() {
        assertThat(service.getHealthConsent(USER).given()).isFalse();
        service.giveHealthConsent(USER);
        service.giveHealthConsent(USER);
        var status = service.getHealthConsent(USER);
        assertThat(status.given()).isTrue();
        assertThat(status.givenAt()).isEqualTo(NOW);
        assertThat(status.withdrawnAt()).isNull();
    }

    @Test
    void withdrawingDeletesTodayAndKeepsTheRestUnlessAsked() {
        service.giveHealthConsent(USER);
        checkIns.save(checkIn(TODAY));
        checkIns.save(checkIn(TODAY.minusDays(1)));

        service.withdrawHealthConsent(USER, false);

        assertThat(service.getHealthConsent(USER).given()).isFalse();
        assertThat(service.getHealthConsent(USER).withdrawnAt()).isEqualTo(NOW);
        assertThat(checkIns.store.values()).extracting(DailyCheckIn::date).containsExactly(TODAY.minusDays(1));

        service.withdrawHealthConsent(USER, true);
        assertThat(checkIns.store).isEmpty();
    }

    private static DailyCheckIn checkIn(LocalDate date) {
        return DailyCheckIn.create(USER, date, new DailyCheckIn.Values(3, 3, 3, 3, List.of(), true, null), NOW);
    }
}
