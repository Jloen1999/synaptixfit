package com.synaptixfit.domain.model.dashboard;

import static org.assertj.core.api.Assertions.assertThat;

import com.synaptixfit.domain.model.dashboard.DashboardReadModels.Deadline;
import com.synaptixfit.domain.model.planner.DeadlineType;
import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** La cuenta atrás de «Tu día» la elige el servidor (ADR 0039): el próximo examen y, si no hay, la próxima entrega. */
class DashboardCountdownTest {

    private static final Instant NOW = Instant.parse("2026-11-13T10:00:00Z");

    private static Deadline deadline(DeadlineType type, int days, boolean completed) {
        return new Deadline(UUID.randomUUID(), type.name() + days, type.name(), NOW.plus(Duration.ofDays(days)),
                completed, null, type);
    }

    @Test
    void anExamWinsOverAnEarlierDelivery() {
        Deadline delivery = deadline(DeadlineType.ASSIGNMENT, 1, false);
        Deadline exam = deadline(DeadlineType.EXAM, 40, false);

        assertThat(Dashboard.countdownOf(List.of(delivery, exam), NOW)).isEqualTo(exam);
    }

    @Test
    void withoutExamsTheNextPendingDeliveryCounts() {
        Deadline later = deadline(DeadlineType.ASSIGNMENT, 9, false);
        Deadline sooner = deadline(DeadlineType.PRESENTATION, 3, false);

        assertThat(Dashboard.countdownOf(List.of(later, sooner), NOW)).isEqualTo(sooner);
    }

    @Test
    void doneOrPastOnesDoNotCount() {
        Deadline done = deadline(DeadlineType.EXAM, 2, true);
        Deadline past = deadline(DeadlineType.EXAM, -1, false);

        assertThat(Dashboard.countdownOf(List.of(done, past), NOW)).isNull();
    }
}
