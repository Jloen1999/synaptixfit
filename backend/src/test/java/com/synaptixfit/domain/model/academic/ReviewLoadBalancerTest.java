package com.synaptixfit.domain.model.academic;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.temporal.ChronoUnit;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** Repasos sin picos (ADR 0042): ±1 día, ±2 en intervalos largos, nunca adelantar un intervalo ≤ 2 días. */
class ReviewLoadBalancerTest {

    private static final ZoneId ZONE = ZoneId.of("Europe/Madrid");
    private static final Instant NOW = Instant.parse("2026-11-15T09:00:00Z");

    private static Instant in(int days) {
        return NOW.plus(days, ChronoUnit.DAYS);
    }

    private static LocalDate day(int days) {
        return LocalDate.ofInstant(in(days), ZONE);
    }

    /** Pares (días desde hoy, repasos ese día). */
    private static ReviewLoadBalancer.Load load(int... dayAndCount) {
        Map<LocalDate, Integer> m = new HashMap<>();
        for (int i = 0; i < dayAndCount.length; i += 2) {
            m.put(day(dayAndCount[i]), dayAndCount[i + 1]);
        }
        return new ReviewLoadBalancer.Load(m, ZONE);
    }

    @Test
    void withoutLoadTheDateStays() {
        assertThat(ReviewLoadBalancer.balance(in(6), 6, ReviewLoadBalancer.Load.NONE)).isEqualTo(in(6));
    }

    @Test
    void aBusyDayMovesTheReviewToTheQuieterNeighbourKeepingTheTime() {
        assertThat(ReviewLoadBalancer.balance(in(6), 6, load(6, 5, 5, 3, 7, 1))).isEqualTo(in(7));
    }

    @Test
    void onATieTheEarlierDayWins() {
        assertThat(ReviewLoadBalancer.balance(in(6), 6, load(6, 5, 5, 1, 7, 1))).isEqualTo(in(5));
    }

    @Test
    void itOnlyMovesIfAnotherDayHasFewerReviews() {
        assertThat(ReviewLoadBalancer.balance(in(6), 6, load(6, 2, 5, 2, 7, 2))).isEqualTo(in(6));
    }

    @Test
    void aOneDayIntervalNeverMoves() {
        assertThat(ReviewLoadBalancer.balance(in(1), 1, load(1, 9))).isEqualTo(in(1));
    }

    @Test
    void aTwoDayIntervalCanOnlyBeDelayed() {
        assertThat(ReviewLoadBalancer.balance(in(2), 2, load(2, 5, 1, 0, 3, 4))).isEqualTo(in(3));
        assertThat(ReviewLoadBalancer.balance(in(2), 2, load(2, 5, 1, 0, 3, 5))).isEqualTo(in(2));
    }

    @Test
    void shortIntervalsMoveOneDayAndLongOnesUpToTwo() {
        // Los días que no salen tienen 0 repasos.
        assertThat(ReviewLoadBalancer.balance(in(10), 10, load(10, 6, 9, 6, 11, 6, 8, 0, 12, 0)))
                .isEqualTo(in(10));
        assertThat(ReviewLoadBalancer.balance(in(20), 20, load(20, 6, 19, 6, 21, 6, 22, 6))).isEqualTo(in(18));
        assertThat(ReviewLoadBalancer.balance(in(20), 20, load(20, 6, 18, 6, 19, 6, 21, 6, 22, 6)))
                .isEqualTo(in(20));
    }

    @Test
    void theMaterialBeingReviewedDoesNotCountAgainstItself() {
        UUID self = UUID.randomUUID();
        ReviewLoadBalancer.Load l = ReviewLoadBalancer.Load.of(List.of(
                new ReviewLoadBalancer.Scheduled(self, in(6)),
                new ReviewLoadBalancer.Scheduled(UUID.randomUUID(), in(6))), self, ZONE);

        assertThat(l.on(day(6))).isEqualTo(1);
    }
}
