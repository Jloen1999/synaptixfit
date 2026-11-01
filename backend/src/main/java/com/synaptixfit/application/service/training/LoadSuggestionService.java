package com.synaptixfit.application.service.training;

import com.synaptixfit.application.port.input.training.GetLoadSuggestionsUseCase;
import com.synaptixfit.domain.exception.training.SessionNotFoundException;
import com.synaptixfit.domain.model.training.Routine;
import com.synaptixfit.domain.model.training.RoutineDay;
import com.synaptixfit.domain.model.training.TrainingSession;
import com.synaptixfit.domain.model.training.generation.GoalParameters;
import com.synaptixfit.domain.model.training.generation.LoadSuggestion;
import com.synaptixfit.domain.model.training.generation.LoadSuggestions;
import com.synaptixfit.domain.port.output.training.RoutineRepositoryPort;
import com.synaptixfit.domain.port.output.training.TrainingSessionRepositoryPort;
import java.time.Clock;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Implementa {@link GetLoadSuggestionsUseCase}: lee el día de la sesión con {@link RoutineRepositoryPort},
 * las últimas sesiones con {@link TrainingSessionRepositoryPort} y aplica {@link LoadSuggestions}.
 */
public class LoadSuggestionService implements GetLoadSuggestionsUseCase {

    /**
     * Sesiones que se miran hacia atrás: más allá de
     * {@value com.synaptixfit.domain.model.training.generation.ProgressionCalculator#INACTIVITY_DAYS} días no hay
     * propuesta, y ni entrenando dos veces al día se pasa de esta cifra en ese plazo.
     */
    static final int WINDOW = 60;

    private final TrainingSessionRepositoryPort sessions;
    private final RoutineRepositoryPort routines;
    private final Clock clock;

    public LoadSuggestionService(TrainingSessionRepositoryPort sessions, RoutineRepositoryPort routines,
                                 Clock clock) {
        this.sessions = sessions;
        this.routines = routines;
        this.clock = clock;
    }

    @Override
    public List<LoadSuggestion> loadSuggestions(UUID userId, UUID sessionId) {
        TrainingSession session = sessions.findById(sessionId).filter(s -> s.isOwnedBy(userId))
                .orElseThrow(() -> new SessionNotFoundException(sessionId));
        Instant now = clock.instant();
        if (session.isCompleted() || session.isStale(now) || session.routineId() == null
                || session.dayId() == null) {
            return List.of();
        }
        Optional<Routine> routine = routines.findById(session.routineId());
        Optional<RoutineDay> day = routine.flatMap(r -> r.findDay(session.dayId()));
        if (day.isEmpty() || day.get().exercises().isEmpty()) {
            return List.of();
        }
        return LoadSuggestions.forDay(day.get().exercises(), sessions.recentCompleted(userId, WINDOW),
                GoalParameters.of(routine.get().goal()), now);
    }
}
