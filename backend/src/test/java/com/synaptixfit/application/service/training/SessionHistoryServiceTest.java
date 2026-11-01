package com.synaptixfit.application.service.training;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.domain.exception.training.SessionNotFoundException;
import com.synaptixfit.domain.exception.training.SessionNotCompletedException;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.training.PersonalRecord;
import com.synaptixfit.domain.model.training.SessionHistoryEntry;
import com.synaptixfit.domain.model.training.SessionLabel;
import com.synaptixfit.domain.model.training.SessionSet;
import com.synaptixfit.domain.model.training.SessionType;
import com.synaptixfit.domain.model.training.TrainingSession;
import com.synaptixfit.domain.model.training.generation.CompletedSessionSummary;
import com.synaptixfit.domain.model.training.generation.CompletedSessionSummary.PerformedSet;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** Historial con nombres de día y récords ({@link SessionHistoryService}) con dobles en memoria. */
class SessionHistoryServiceTest {

    private final UUID userId = UUID.randomUUID();
    private final UUID bench = UUID.randomUUID();
    private final TrainingFakes.Sessions sessions = new TrainingFakes.Sessions();

    private TrainingSession completed(UUID id, String at) {
        Instant when = Instant.parse(at);
        return new TrainingSession(id, userId, UUID.randomUUID(), UUID.randomUUID(), SessionType.ROUTINE,
                when.minusSeconds(3600), when, 60, 7, 300.0, 150, List.of());
    }

    private CompletedSessionSummary summary(UUID id, String at, double kg) {
        return new CompletedSessionSummary(id, Instant.parse(at), 7, 60, List.of(new PerformedSet(bench,
                "Press de banca", new SessionSet(UUID.randomUUID(), UUID.randomUUID(), 1, 5, kg, true, 0))));
    }

    @Test
    void historyCarriesTheDayNameAndTheRecordsBrokenInEachSession() {
        UUID first = UUID.randomUUID();
        UUID second = UUID.randomUUID();
        sessions.save(completed(first, "2026-10-10T18:00:00Z"));
        sessions.save(completed(second, "2026-10-13T18:00:00Z"));
        sessions.recent = List.of(summary(first, "2026-10-10T18:00:00Z", 60),
                summary(second, "2026-10-13T18:00:00Z", 62.5));
        SessionHistoryService service = new SessionHistoryService(sessions, ids -> Map.of(
                second, new SessionLabel(second, "Fuerza", "Empuje: pecho y hombro", 2, 5)), java.time.Clock.systemUTC(), java.time.ZoneOffset.UTC);

        List<SessionHistoryEntry> items = service.listHistory(userId, new PageRequest(0, 20)).items();

        SessionHistoryEntry latest = items.stream().filter(e -> e.session().id().equals(second)).findFirst()
                .orElseThrow();
        assertThat(latest.label().dayName()).isEqualTo("Empuje: pecho y hombro");
        assertThat(latest.records()).singleElement().extracting(PersonalRecord::weightKg).isEqualTo(62.5);
        SessionHistoryEntry oldest = items.stream().filter(e -> e.session().id().equals(first)).findFirst()
                .orElseThrow();
        assertThat(oldest.label()).isNull();
        assertThat(oldest.records()).isEmpty();
    }

    @Test
    void personalRecordsListTheBestMarkPerExercise() {
        sessions.recent = List.of(summary(UUID.randomUUID(), "2026-10-10T18:00:00Z", 60),
                summary(UUID.randomUUID(), "2026-10-13T18:00:00Z", 55));
        SessionHistoryService service = new SessionHistoryService(sessions, ids -> Map.of(), java.time.Clock.systemUTC(), java.time.ZoneOffset.UTC);

        assertThat(service.listPersonalRecords(userId)).singleElement()
                .extracting(PersonalRecord::weightKg).isEqualTo(60.0);
    }

    @Test
    void highlightsNeedAFinishedOwnSession() {
        UUID done = UUID.randomUUID();
        sessions.save(completed(done, "2026-10-13T18:00:00Z"));
        sessions.recent = List.of(summary(done, "2026-10-13T18:00:00Z", 60));
        TrainingSession running = sessions.save(TrainingSession.start(userId, null, null,
                Instant.parse("2026-10-14T18:00:00Z")));
        SessionHistoryService service = new SessionHistoryService(sessions, ids -> Map.of(), java.time.Clock.systemUTC(), java.time.ZoneOffset.UTC);

        assertThat(service.highlights(userId, done).volumeKg()).isEqualTo(300.0);
        assertThatThrownBy(() -> service.highlights(userId, running.id()))
                .isInstanceOf(SessionNotCompletedException.class);
        assertThatThrownBy(() -> service.highlights(UUID.randomUUID(), done))
                .isInstanceOf(SessionNotFoundException.class);
    }
}
