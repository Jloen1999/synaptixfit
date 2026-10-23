package com.synaptixfit.application.service.training;

import com.synaptixfit.application.port.input.training.ListLastPerformanceUseCase;
import com.synaptixfit.application.port.input.training.ListPersonalRecordsUseCase;
import com.synaptixfit.application.port.input.training.ListSessionHistoryUseCase;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import com.synaptixfit.domain.model.training.PersonalRecord;
import com.synaptixfit.domain.model.training.PersonalRecords;
import com.synaptixfit.domain.model.training.SessionHistoryEntry;
import com.synaptixfit.domain.model.training.SessionLabel;
import com.synaptixfit.domain.model.training.TrainingSession;
import com.synaptixfit.domain.model.training.generation.CompletedSessionSummary;
import com.synaptixfit.domain.port.output.training.SessionLabelQueryPort;
import com.synaptixfit.domain.port.output.training.TrainingSessionRepositoryPort;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Historial con nombres y récords personales. Lee las sesiones con {@link TrainingSessionRepositoryPort},
 * sus nombres con {@link SessionLabelQueryPort} y calcula los récords con {@link PersonalRecords}.
 */
public class SessionHistoryService implements ListSessionHistoryUseCase, ListPersonalRecordsUseCase,
        ListLastPerformanceUseCase {

    /** Sesiones que se recorren para los récords: de sobra para años de entrenamiento habitual. */
    static final int RECORDS_WINDOW = 1000;

    private final TrainingSessionRepositoryPort sessions;
    private final SessionLabelQueryPort labels;

    public SessionHistoryService(TrainingSessionRepositoryPort sessions, SessionLabelQueryPort labels) {
        this.sessions = sessions;
        this.labels = labels;
    }

    @Override
    public PageResult<SessionHistoryEntry> listHistory(UUID userId, PageRequest page) {
        PageResult<TrainingSession> result = sessions.findByUser(userId, true, page);
        List<UUID> ids = result.items().stream().map(TrainingSession::id).toList();
        Map<UUID, SessionLabel> names = ids.isEmpty() ? Map.of() : labels.labels(ids);
        Map<UUID, List<PersonalRecord>> records = ids.isEmpty() ? Map.of()
                : PersonalRecords.brokenBySession(completed(userId));
        List<SessionHistoryEntry> entries = result.items().stream()
                .map(s -> new SessionHistoryEntry(s, names.get(s.id()), records.getOrDefault(s.id(), List.of())))
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

    private List<CompletedSessionSummary> completed(UUID userId) {
        return sessions.recentCompleted(userId, RECORDS_WINDOW);
    }
}
