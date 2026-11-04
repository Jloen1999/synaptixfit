package com.synaptixfit.application.service.training;

import com.synaptixfit.domain.model.training.ExerciseProgress;
import com.synaptixfit.application.port.input.training.GetExerciseProgressUseCase;
import com.synaptixfit.application.port.input.training.GetSessionHighlightsUseCase;
import com.synaptixfit.application.port.input.training.ListLastPerformanceUseCase;
import com.synaptixfit.application.port.input.training.ListOpenSessionsUseCase;
import com.synaptixfit.application.port.input.training.ListPersonalRecordsUseCase;
import com.synaptixfit.application.port.input.training.ListSessionHistoryUseCase;
import com.synaptixfit.domain.exception.training.SessionNotCompletedException;
import com.synaptixfit.domain.exception.training.SessionNotFoundException;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import com.synaptixfit.domain.model.training.OpenTrainingSession;
import com.synaptixfit.domain.model.training.PersonalRecord;
import com.synaptixfit.domain.model.training.PersonalRecords;
import com.synaptixfit.domain.model.training.SessionHighlights;
import com.synaptixfit.domain.model.training.SessionHistoryEntry;
import com.synaptixfit.domain.model.training.SessionLabel;
import com.synaptixfit.domain.model.training.TrainingSession;
import com.synaptixfit.domain.model.training.generation.CompletedSessionSummary;
import com.synaptixfit.domain.port.output.training.SessionLabelQueryPort;
import com.synaptixfit.domain.port.output.training.TrainingSessionRepositoryPort;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Historial con nombres y récords personales. Lee las sesiones con {@link TrainingSessionRepositoryPort},
 * sus nombres con {@link SessionLabelQueryPort} y calcula los récords con {@link PersonalRecords}.
 * También lista las sesiones sin terminar (sección «Sin terminar»), marcando las abandonadas.
 */
public class SessionHistoryService implements ListSessionHistoryUseCase, ListPersonalRecordsUseCase,
        ListLastPerformanceUseCase, GetSessionHighlightsUseCase, ListOpenSessionsUseCase,
        GetExerciseProgressUseCase {

    /** Sesiones que se recorren para los récords: de sobra para años de entrenamiento habitual. */
    static final int RECORDS_WINDOW = 1000;

    private final TrainingSessionRepositoryPort sessions;
    private final SessionLabelQueryPort labels;
    private final Clock clock;
    private final ZoneId zone;

    /** @param zone zona que define el «día» de una sesión (la de sesiones e indicadores) */
    public SessionHistoryService(TrainingSessionRepositoryPort sessions, SessionLabelQueryPort labels, Clock clock,
                                 ZoneId zone) {
        this.sessions = sessions;
        this.labels = labels;
        this.clock = clock;
        this.zone = zone;
    }

    @Override
    public List<OpenTrainingSession> listOpen(UUID userId) {
        List<TrainingSession> open = sessions.findOpen(userId);
        if (open.isEmpty()) {
            return List.of();
        }
        Instant now = clock.instant();
        Map<UUID, SessionLabel> names = labels.labels(open.stream().map(TrainingSession::id).toList());
        return open.stream().map(s -> new OpenTrainingSession(s, names.get(s.id()), s.isStale(now))).toList();
    }

    @Override
    public PageResult<SessionHistoryEntry> listHistory(UUID userId, PageRequest page) {
        PageResult<TrainingSession> result = sessions.findByUser(userId, true, page);
        List<UUID> ids = result.items().stream().map(TrainingSession::id).toList();
        Map<UUID, SessionLabel> names = ids.isEmpty() ? Map.of() : labels.labels(ids);
        Map<UUID, List<PersonalRecord>> records = ids.isEmpty() ? Map.of()
                : PersonalRecords.brokenBySession(completed(userId));
        LocalDate today = LocalDate.ofInstant(clock.instant(), zone);
        List<SessionHistoryEntry> entries = result.items().stream()
                .map(s -> new SessionHistoryEntry(s, names.get(s.id()), records.getOrDefault(s.id(), List.of()),
                        s.canUnmark(today, zone)))
                .toList();
        return new PageResult<>(entries, result.page(), result.size(), result.totalItems());
    }

    @Override
    public List<PersonalRecord> listPersonalRecords(UUID userId) {
        return PersonalRecords.best(completed(userId));
    }

    @Override
    public List<PersonalRecord> lastPerformance(UUID userId) {
        return List.copyOf(PersonalRecords.lastBest(completed(userId)).values());
    }

    @Override
    public SessionHighlights highlights(UUID userId, UUID sessionId) {
        TrainingSession session = sessions.findById(sessionId).filter(s -> s.isOwnedBy(userId))
                .orElseThrow(() -> new SessionNotFoundException(sessionId));
        if (!session.isCompleted()) {
            throw new SessionNotCompletedException();
        }
        return SessionHighlights.of(sessionId, completed(userId))
                .orElseThrow(() -> new SessionNotFoundException(sessionId));
    }

    @Override
    public List<ExerciseProgress.Point> exerciseProgress(UUID userId, UUID exerciseId) {
        return ExerciseProgress.of(exerciseId, completed(userId), zone);
    }

    private List<CompletedSessionSummary> completed(UUID userId) {
        return sessions.recentCompleted(userId, RECORDS_WINDOW);
    }
}
