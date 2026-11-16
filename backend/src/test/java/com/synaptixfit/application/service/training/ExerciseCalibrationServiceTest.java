package com.synaptixfit.application.service.training;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.application.port.input.training.CalibrateExerciseUseCase;
import com.synaptixfit.application.port.input.training.ListSessionCalibrationsUseCase;
import com.synaptixfit.domain.exception.training.SessionNotFoundException;
import com.synaptixfit.domain.exception.training.SessionSetNotFoundException;
import com.synaptixfit.domain.model.shared.Visibility;
import com.synaptixfit.domain.model.training.ExerciseParameters;
import com.synaptixfit.domain.model.training.ExerciseRef;
import com.synaptixfit.domain.model.training.MeasurementType;
import com.synaptixfit.domain.model.training.Modality;
import com.synaptixfit.domain.model.training.PlannedExercise;
import com.synaptixfit.domain.model.training.RepRange;
import com.synaptixfit.domain.model.training.Routine;
import com.synaptixfit.domain.model.training.RoutineDay;
import com.synaptixfit.domain.model.training.RoutineWeek;
import com.synaptixfit.domain.model.training.SessionSet;
import com.synaptixfit.domain.model.training.TrainingGoal;
import com.synaptixfit.domain.model.training.TrainingSession;
import com.synaptixfit.domain.model.training.WeekType;
import com.synaptixfit.domain.model.training.generation.CompletedSessionSummary;
import com.synaptixfit.domain.model.training.generation.CompletedSessionSummary.PerformedSet;
import com.synaptixfit.domain.model.training.load.CalibrationAnswer;
import com.synaptixfit.domain.model.training.load.CalibrationStep;
import com.synaptixfit.domain.model.training.load.ExerciseCalibrationRecord;
import com.synaptixfit.domain.model.training.load.LoadProfile;
import com.synaptixfit.domain.model.training.load.LoadType;
import com.synaptixfit.domain.port.output.training.ExerciseCalibrationRepositoryPort;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/**
 * Calibración de la primera sesión (ADR 0054): qué ejercicios se preguntan, el peso de la serie siguiente y que ese
 * peso pasa a los días que aún no se han hecho.
 */
class ExerciseCalibrationServiceTest {

    private static final UUID USER = UUID.randomUUID();
    private static final Instant NOW = Instant.parse("2026-11-16T10:00:00Z");
    private static final ExerciseRef SQUAT = new ExerciseRef(UUID.randomUUID(), "Sentadilla trasera con barra", null,
            null, Modality.STRENGTH, List.of(MeasurementType.REPETITIONS, MeasurementType.WEIGHT), false, 5.0, true,
            new LoadProfile(LoadType.BARBELL, 0.35, 20.0, 60.0, true));
    private static final ExerciseRef PUSH_UP = new ExerciseRef(UUID.randomUUID(), "Flexión de brazos", null, null,
            Modality.STRENGTH, List.of(MeasurementType.REPETITIONS, MeasurementType.WEIGHT), false, 5.0, true,
            new LoadProfile(LoadType.BODYWEIGHT, null, null, null, false));

    private final TrainingFakes.Sessions sessions = new TrainingFakes.Sessions();
    private final TrainingFakes.Routines routines = new TrainingFakes.Routines();
    private final List<ExerciseCalibrationRecord> saved = new ArrayList<>();
    private final ExerciseCalibrationRepositoryPort calibrations = new ExerciseCalibrationRepositoryPort() {
        @Override
        public ExerciseCalibrationRecord save(ExerciseCalibrationRecord c) {
            saved.removeIf(r -> r.sessionId().equals(c.sessionId())
                    && r.plannedExerciseId().equals(c.plannedExerciseId()));
            saved.add(c);
            return c;
        }

        @Override
        public List<ExerciseCalibrationRecord> findBySession(UUID sessionId) {
            return saved.stream().filter(r -> r.sessionId().equals(sessionId)).toList();
        }
    };
    private ExerciseCalibrationService service;
    private Routine routine;
    private RoutineDay monday;
    private RoutineDay wednesday;
    private TrainingSession session;

    @BeforeEach
    void setUp() {
        service = new ExerciseCalibrationService(sessions, routines, calibrations, Clock.fixed(NOW, ZoneOffset.UTC));
        ExerciseParameters squatParams = new ExerciseParameters(3, 8, 150, 30.0, null, null, null, null, null, null,
                new RepRange(8, 10, 3));
        monday = RoutineDay.create(1, "Piernas");
        monday.addExercise(SQUAT, squatParams);
        monday.addExercise(PUSH_UP, new ExerciseParameters(3, 10, 60, null, null, null, null, null));
        wednesday = RoutineDay.create(3, "Piernas otra vez");
        wednesday.addExercise(SQUAT, squatParams);
        routine = routines.save(Routine.create(USER, "Mi rutina", null, Visibility.PRIVATE, TrainingGoal.HYPERTROPHY,
                null, null, List.of(RoutineWeek.create(1, null, WeekType.LOAD, List.of(monday, wednesday))), NOW));
        session = sessions.save(TrainingSession.start(USER, routine.id(), monday.id(), NOW.minusSeconds(900)));
    }

    private PlannedExercise squatOn(RoutineDay day) {
        return routine.day(day.id()).exercises().getFirst();
    }

    @Test
    void onlyWeightedExercisesWithoutRecentHistoryAreAsked() {
        assertThat(service.calibrations(USER, session.id()))
                .extracting(ListSessionCalibrationsUseCase.Target::exerciseId).containsExactly(SQUAT.id());

        sessions.recent.add(new CompletedSessionSummary(UUID.randomUUID(), NOW.minus(Duration.ofDays(4)), 7, 40,
                List.of(new PerformedSet(SQUAT.id(), "Sentadilla", new SessionSet(UUID.randomUUID(),
                        UUID.randomUUID(), 1, 8, 40.0, true, 0, null, null, SQUAT.id())))));
        assertThat(service.calibrations(USER, session.id())).isEmpty();
    }

    @Test
    void fourOrMoreLeftRaisesTheNextSetAndTheDaysStillToDo() {
        session.recordSet(squatOn(monday).id(), SQUAT.id(), 1, 8, 30.0, true, 0, null, null);

        ExerciseCalibrationRecord r = service.calibrate(new CalibrateExerciseUseCase.Command(USER, session.id(),
                squatOn(monday).id(), 1, CalibrationAnswer.FOUR_PLUS));

        assertThat(r.step()).isEqualTo(CalibrationStep.UP);
        assertThat(r.nextWeightKg()).isEqualTo(35.0);
        assertThat(squatOn(wednesday).parameters().weightKg()).isEqualTo(35.0);
        assertThat(squatOn(wednesday).parameters().repRange()).isEqualTo(new RepRange(8, 10, 3));
        assertThat(service.calibrations(USER, session.id())).singleElement().satisfies(t -> {
            assertThat(t.answer()).isEqualTo(CalibrationAnswer.FOUR_PLUS);
            assertThat(t.nextWeightKg()).isEqualTo(35.0);
            assertThat(t.setNumber()).isEqualTo(1);
        });
    }

    @Test
    void missingTheMinimumOfTheRangeLowersTheWeightWhateverTheAnswer() {
        session.recordSet(squatOn(monday).id(), SQUAT.id(), 1, 6, 30.0, true, 2, null, null);

        ExerciseCalibrationRecord r = service.calibrate(new CalibrateExerciseUseCase.Command(USER, session.id(),
                squatOn(monday).id(), 1, CalibrationAnswer.THREE));

        assertThat(r.step()).isEqualTo(CalibrationStep.DOWN);
        assertThat(r.nextWeightKg()).isEqualTo(25.0);
    }

    @Test
    void answeringAgainReplacesTheAnswer() {
        session.recordSet(squatOn(monday).id(), SQUAT.id(), 1, 8, 30.0, true, 0, null, null);
        service.calibrate(new CalibrateExerciseUseCase.Command(USER, session.id(), squatOn(monday).id(), 1,
                CalibrationAnswer.FOUR_PLUS));
        service.calibrate(new CalibrateExerciseUseCase.Command(USER, session.id(), squatOn(monday).id(), 1,
                CalibrationAnswer.THREE));

        assertThat(saved).singleElement().satisfies(c -> assertThat(c.answer()).isEqualTo(CalibrationAnswer.THREE));
    }

    @Test
    void onlyTheFirstSetOfAnExerciseThatIsCalibratedIsAcceptedAndTheRoutineIsLeftAlone() {
        session.recordSet(squatOn(monday).id(), SQUAT.id(), 1, 8, 30.0, true, 0, null, null);
        session.recordSet(squatOn(monday).id(), SQUAT.id(), 2, 8, 30.0, true, 0, null, null);
        assertThatThrownBy(() -> service.calibrate(new CalibrateExerciseUseCase.Command(USER, session.id(),
                squatOn(monday).id(), 2, CalibrationAnswer.FOUR_PLUS))).isInstanceOf(SessionSetNotFoundException.class);

        // Con historial reciente ya no es la primera vez: tampoco se acepta.
        sessions.recent.add(new CompletedSessionSummary(UUID.randomUUID(), NOW.minus(Duration.ofDays(4)), 7, 40,
                List.of(new PerformedSet(SQUAT.id(), "Sentadilla", new SessionSet(UUID.randomUUID(),
                        UUID.randomUUID(), 1, 8, 40.0, true, 0, null, null, SQUAT.id())))));
        assertThatThrownBy(() -> service.calibrate(new CalibrateExerciseUseCase.Command(USER, session.id(),
                squatOn(monday).id(), 1, CalibrationAnswer.FOUR_PLUS))).isInstanceOf(SessionSetNotFoundException.class);
        assertThat(squatOn(wednesday).parameters().weightKg()).isEqualTo(30.0);
        assertThat(saved).isEmpty();
    }

    @Test
    void aSetNotYetSavedOrSomeoneElsesSessionIsNotFound() {
        assertThatThrownBy(() -> service.calibrate(new CalibrateExerciseUseCase.Command(USER, session.id(),
                squatOn(monday).id(), 1, CalibrationAnswer.THREE))).isInstanceOf(SessionSetNotFoundException.class);
        assertThatThrownBy(() -> service.calibrations(UUID.randomUUID(), session.id()))
                .isInstanceOf(SessionNotFoundException.class);
    }
}
