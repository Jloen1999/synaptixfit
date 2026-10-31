package com.synaptixfit.application.service.training;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.application.port.input.insights.GetCrossRegulationUseCase;
import com.synaptixfit.application.port.input.training.GetSessionAdaptationUseCase;
import com.synaptixfit.domain.exception.training.SessionNotFoundException;
import com.synaptixfit.domain.model.insights.AcwrZone;
import com.synaptixfit.domain.model.insights.CrossRegulationState;
import com.synaptixfit.domain.model.insights.CrossRegulationView;
import com.synaptixfit.domain.model.shared.Visibility;
import com.synaptixfit.domain.model.training.ExerciseParameters;
import com.synaptixfit.domain.model.training.PlannedExercise;
import com.synaptixfit.domain.model.training.Routine;
import com.synaptixfit.domain.model.training.RoutineDay;
import com.synaptixfit.domain.model.training.RoutineWeek;
import com.synaptixfit.domain.model.training.SessionAdaptation.Reason;
import com.synaptixfit.domain.model.training.TrainingGoal;
import com.synaptixfit.domain.model.training.TrainingSession;
import com.synaptixfit.domain.model.training.WeekType;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/** La sesión se adapta con examen cerca y nunca deja fuera series ya hechas ni toca sesiones terminadas. */
class SessionAdaptationServiceTest {

    private static final UUID USER = UUID.randomUUID();
    private static final Instant NOW = Instant.parse("2026-10-25T10:00:00Z");

    private final TrainingFakes.Sessions sessions = new TrainingFakes.Sessions();
    private final TrainingFakes.Routines routines = new TrainingFakes.Routines();
    private final TrainingFakes.CheckIns checkIns = new TrainingFakes.CheckIns();
    /** Examen cerca: la fórmula 3A deja el volumen al 50 %. */
    private final GetCrossRegulationUseCase examSoon = (userId, tz) -> new CrossRegulationView(
            new CrossRegulationState(userId, 0, 0, 90, 1, NOW), null, AcwrZone.NO_DATA, 1, 0.5);
    private SessionAdaptationService service;
    private Routine routine;
    private RoutineDay day;

    @BeforeEach
    void setUp() {
        service = new SessionAdaptationService(sessions, routines, checkIns, examSoon, Clock.fixed(NOW, ZoneOffset.UTC),
                ZoneOffset.UTC);
        var bench = TrainingFakes.strength("Press de banca", "Pectoral mayor").toRef();
        day = RoutineDay.create(1, "Torso");
        day.addExercise(bench, new ExerciseParameters(4, 10, 90, 50.0, null, null, null, null));
        routine = routines.save(Routine.create(USER, "Mi rutina", null, Visibility.PRIVATE, TrainingGoal.HYPERTROPHY,
                null, null, List.of(RoutineWeek.create(1, null, WeekType.LOAD, List.of(day))), NOW));
    }

    private PlannedExercise planned() {
        return routine.day(day.id()).exercises().getFirst();
    }

    @Test
    void anExamSoonHalvesTheSetsButNeverBelowWhatIsAlreadyDone() {
        TrainingSession session = sessions.save(TrainingSession.start(USER, routine.id(), day.id(), NOW));

        GetSessionAdaptationUseCase.Result result = service.adaptation(USER, session.id(), null);
        assertThat(result.adaptation().reasons()).containsExactly(Reason.EXAM_SOON);
        assertThat(result.sets()).containsEntry(planned().id(), 2);

        // Ya hizo 3 series antes de que se recalculara: se respetan.
        for (int n = 1; n <= 3; n++) {
            session.recordSet(planned().id(), n, 10, 50.0, true, 0);
        }
        sessions.save(session);
        assertThat(service.adaptation(USER, session.id(), null).sets()).containsEntry(planned().id(), 3);
    }

    @Test
    void finishedSessionsAreNotAdaptedAndForeignOnesAreNotFound() {
        TrainingSession session = TrainingSession.start(USER, routine.id(), day.id(), NOW.minusSeconds(3600));
        session.complete(1800, 6, 200, 100, NOW);
        sessions.save(session);

        GetSessionAdaptationUseCase.Result result = service.adaptation(USER, session.id(), null);
        assertThat(result.adaptation().adapted()).isFalse();
        assertThat(result.sets()).containsEntry(planned().id(), 4);
        assertThatThrownBy(() -> service.adaptation(UUID.randomUUID(), session.id(), null))
                .isInstanceOf(SessionNotFoundException.class);
    }

    @Test
    void aFreeSessionHasNoPlannedSets() {
        TrainingSession free = sessions.save(TrainingSession.start(USER, null, null, NOW));
        assertThat(service.adaptation(USER, free.id(), null).sets()).isEmpty();
    }
}
