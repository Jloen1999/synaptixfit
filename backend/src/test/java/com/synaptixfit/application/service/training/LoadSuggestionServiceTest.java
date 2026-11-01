package com.synaptixfit.application.service.training;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.domain.exception.training.SessionNotFoundException;
import com.synaptixfit.domain.model.shared.Visibility;
import com.synaptixfit.domain.model.training.ExerciseParameters;
import com.synaptixfit.domain.model.training.PlannedExercise;
import com.synaptixfit.domain.model.training.Routine;
import com.synaptixfit.domain.model.training.RoutineDay;
import com.synaptixfit.domain.model.training.RoutineWeek;
import com.synaptixfit.domain.model.training.SessionSet;
import com.synaptixfit.domain.model.training.TrainingGoal;
import com.synaptixfit.domain.model.training.TrainingSession;
import com.synaptixfit.domain.model.training.WeekType;
import com.synaptixfit.domain.model.training.generation.CompletedSessionSummary;
import com.synaptixfit.domain.model.training.generation.CompletedSessionSummary.PerformedSet;
import com.synaptixfit.domain.model.training.generation.LoadSuggestion.Metric;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/** La propuesta de carga solo se da en sesiones propias en curso de un día de rutina. */
class LoadSuggestionServiceTest {

    private static final UUID USER = UUID.randomUUID();
    private static final Instant NOW = Instant.parse("2026-11-02T10:00:00Z");

    private final TrainingFakes.Sessions sessions = new TrainingFakes.Sessions();
    private final TrainingFakes.Routines routines = new TrainingFakes.Routines();
    private LoadSuggestionService service;
    private Routine routine;
    private RoutineDay day;

    @BeforeEach
    void setUp() {
        service = new LoadSuggestionService(sessions, routines, Clock.fixed(NOW, ZoneOffset.UTC));
        var bench = TrainingFakes.strength("Press de banca", "Pectoral mayor").toRef();
        day = RoutineDay.create(1, "Torso");
        day.addExercise(bench, new ExerciseParameters(3, 15, 90, 40.0, null, null, null, null));
        routine = routines.save(Routine.create(USER, "Mi rutina", null, Visibility.PRIVATE, TrainingGoal.HYPERTROPHY,
                null, null, List.of(RoutineWeek.create(1, null, WeekType.LOAD, List.of(day))), NOW));
        PlannedExercise p = planned();
        // Hace 3 días: 3 × 15 con 40 kg y RPE 6.
        sessions.recent.add(new CompletedSessionSummary(UUID.randomUUID(), NOW.minus(Duration.ofDays(3)), 6, 45,
                List.of(1, 2, 3).stream().map(n -> new PerformedSet(p.exerciseId(), "Press de banca",
                        new SessionSet(UUID.randomUUID(), p.id(), n, 15, 40.0, true, 0, null, null,
                                p.exerciseId()))).toList()));
    }

    private PlannedExercise planned() {
        return routine.day(day.id()).exercises().getFirst();
    }

    @Test
    void anOpenRoutineSessionGetsTheProposalForEachExercise() {
        TrainingSession session = sessions.save(TrainingSession.start(USER, routine.id(), day.id(),
                NOW.minusSeconds(600)));

        assertThat(service.loadSuggestions(USER, session.id())).singleElement().satisfies(s -> {
            assertThat(s.plannedExerciseId()).isEqualTo(planned().id());
            assertThat(s.metric()).isEqualTo(Metric.WEIGHT);
            assertThat(s.suggested()).isEqualTo(42.0);
        });
    }

    @Test
    void finishedFreeOrForeignSessionsGetNothing() {
        TrainingSession done = TrainingSession.start(USER, routine.id(), day.id(), NOW.minusSeconds(3600));
        done.complete(1800, 6, 200, 100, NOW);
        sessions.save(done);
        TrainingSession free = sessions.save(TrainingSession.start(USER, null, null, NOW.minusSeconds(60)));

        assertThat(service.loadSuggestions(USER, done.id())).isEmpty();
        assertThat(service.loadSuggestions(USER, free.id())).isEmpty();
        assertThatThrownBy(() -> service.loadSuggestions(UUID.randomUUID(), done.id()))
                .isInstanceOf(SessionNotFoundException.class);
    }
}
