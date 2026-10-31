package com.synaptixfit.domain.model.dashboard;

import static org.assertj.core.api.Assertions.assertThat;

import com.synaptixfit.domain.model.dashboard.DashboardReadModels.NextTrainingDay;
import java.time.Instant;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class NextTrainingDayTest {

    private static final Instant NOW = Instant.parse("2026-10-20T18:00:00Z");

    private static NextTrainingDay day(String status, Instant openSince) {
        return new NextTrainingDay(UUID.randomUUID(), "Rutina", UUID.randomUUID(), 1, UUID.randomUUID(), 1, "Pierna",
                status, openSince);
    }

    @Test
    void aDayWithARecentOpenSessionStaysInProgress() {
        assertThat(day("en_progreso", NOW.minusSeconds(3_600)).effective(NOW).dayStatus()).isEqualTo("en_progreso");
    }

    @Test
    void anAbandonedOrSessionlessDayIsPendingAgain() {
        assertThat(day("en_progreso", NOW.minusSeconds(7 * 3_600)).effective(NOW).dayStatus()).isEqualTo("pendiente");
        assertThat(day("en_progreso", null).effective(NOW).dayStatus()).isEqualTo("pendiente");
        assertThat(day("pendiente", null).effective(NOW).dayStatus()).isEqualTo("pendiente");
    }
}
