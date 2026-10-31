package com.synaptixfit.domain.model.dashboard;

import static org.assertj.core.api.Assertions.assertThat;

import com.synaptixfit.domain.model.dashboard.DashboardReadModels.CalendarBlock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** El aviso de bloques sin hacer nombra el más reciente para reconocerlo de un vistazo. */
class MissedBlocksBannerTest {

    private static final ZoneId MADRID = ZoneId.of("Europe/Madrid");
    private static final LocalDate TODAY = LocalDate.of(2026, 10, 21);

    private static CalendarBlock block(String type, String start, String subject, String topics) {
        Instant s = Instant.parse(start);
        return new CalendarBlock(UUID.randomUUID(), type, s, s.plusSeconds(3600), false, subject, topics);
    }

    @Test
    void namesTheLatestMissedBlockWithItsTime() {
        SmartBanner banner = new SmartBanner(SmartBanner.Type.MISSED_BLOCKS, Map.of("count", 2));
        SmartBanner described = SmartBannerRules.describeLatestMissed(banner, List.of(
                block("estudio", "2026-10-20T08:00:00Z", "Álgebra", null),
                block("deporte", "2026-10-21T14:00:00Z", null, null)), TODAY, MADRID);

        assertThat(described.params()).containsEntry("count", 2).containsEntry("startMinutes", 16 * 60)
                .containsEntry("yesterday", 0);
        // Sin asignatura ni temas, el cliente usa el tipo.
        assertThat(described.labels()).containsEntry("activity", "SPORT").doesNotContainKey("title");
    }

    @Test
    void aBlockFromYesterdayIsMarkedAsSuch() {
        SmartBanner banner = new SmartBanner(SmartBanner.Type.MISSED_BLOCKS, Map.of("count", 1));
        SmartBanner described = SmartBannerRules.describeLatestMissed(banner, List.of(
                block("estudio", "2026-10-20T08:00:00Z", "Álgebra", "Matrices")), TODAY, MADRID);

        assertThat(described.params()).containsEntry("yesterday", 1).containsEntry("startMinutes", 10 * 60);
        assertThat(described.labels()).containsEntry("title", "Álgebra");
    }
}
