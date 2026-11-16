package com.synaptixfit.application.service.training;

import com.synaptixfit.application.port.input.training.CalibrateExerciseUseCase;
import com.synaptixfit.application.port.input.training.ListSessionCalibrationsUseCase;
import com.synaptixfit.domain.exception.training.RoutineExerciseNotFoundException;
import com.synaptixfit.domain.exception.training.SessionAlreadyCompletedException;
import com.synaptixfit.domain.exception.training.SessionNotFoundException;
import com.synaptixfit.domain.exception.training.SessionSetNotFoundException;
import com.synaptixfit.domain.model.shared.Guard;
import com.synaptixfit.domain.model.training.PlannedExercise;
import com.synaptixfit.domain.model.training.RepRange;
import com.synaptixfit.domain.model.training.Routine;
import com.synaptixfit.domain.model.training.RoutineDay;
import com.synaptixfit.domain.model.training.SessionSet;
import com.synaptixfit.domain.model.training.TrainingSession;
import com.synaptixfit.domain.model.training.generation.CompletedSessionSummary;
import com.synaptixfit.domain.model.training.load.ExerciseCalibration;
import com.synaptixfit.domain.model.training.load.ExerciseCalibrationRecord;
import com.synaptixfit.domain.port.output.training.ExerciseCalibrationRepositoryPort;
import com.synaptixfit.domain.port.output.training.RoutineRepositoryPort;
import com.synaptixfit.domain.port.output.training.TrainingSessionRepositoryPort;
import java.time.Clock;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * Calibración del peso en la primera sesión de cada ejercicio (ADR 0054). Implementa
 * {@link ListSessionCalibrationsUseCase} (qué ejercicios del día se calibran, con {@link ExerciseCalibration#needed})
 * y {@link CalibrateExerciseUseCase} (aplica {@link ExerciseCalibration#adjust} a la serie guardada, guarda la
 * respuesta con {@link ExerciseCalibrationRepositoryPort} y deja el peso en la rutina con
 * {@link Routine#applyCalibratedWeight}).
 */
public class ExerciseCalibrationService implements ListSessionCalibrationsUseCase, CalibrateExerciseUseCase {

    /** Sesiones que se miran para saber si ya hizo el ejercicio con kilos en las últimas semanas. */
    static final int HISTORY_SESSIONS = 60;

    private final TrainingSessionRepositoryPort sessions;
    private final RoutineRepositoryPort routines;
    private final ExerciseCalibrationRepositoryPort calibrations;
    private final Clock clock;

    public ExerciseCalibrationService(TrainingSessionRepositoryPort sessions, RoutineRepositoryPort routines,
                                      ExerciseCalibrationRepositoryPort calibrations, Clock clock) {
        this.sessions = sessions;
        this.routines = routines;
        this.calibrations = calibrations;
        this.clock = clock;
    }

    @Override
    public List<Target> calibrations(UUID userId, UUID sessionId) {
        TrainingSession session = owned(userId, sessionId);
        Instant now = clock.instant();
        if (session.isCompleted() || session.isStale(now)) {
            return List.of();
        }
        List<PlannedExercise> planned = dayOf(session).map(RoutineDay::exercises).orElse(List.of());
        if (planned.isEmpty()) {
            return List.of();
        }
        Map<UUID, ExerciseCalibrationRecord> answered = calibrations.findBySession(sessionId).stream()
                .filter(r -> r.plannedExerciseId() != null)
                .collect(Collectors.toMap(ExerciseCalibrationRecord::plannedExerciseId, Function.identity(),
                        (a, b) -> b));
        List<CompletedSessionSummary> recent = sessions.recentCompleted(userId, HISTORY_SESSIONS);
        return planned.stream()
                .filter(p -> answered.containsKey(p.id()) || ExerciseCalibration.needed(p.exercise(), recent, now))
                .map(p -> {
                    ExerciseCalibrationRecord r = answered.get(p.id());
                    return r == null ? new Target(p.id(), p.exerciseId(), null, null, null, null)
                            : new Target(p.id(), p.exerciseId(), r.answer(), r.setNumber(), r.step(),
                                    r.nextWeightKg());
                })
                .toList();
    }

    @Override
    public ExerciseCalibrationRecord calibrate(Command c) {
        Guard.notNull(c.answer(), "answer");
        TrainingSession session = owned(c.userId(), c.sessionId());
        if (session.isCompleted()) {
            throw new SessionAlreadyCompletedException();
        }
        Instant now = clock.instant();
        String setKey = c.plannedExerciseId() + "/" + c.setNumber();
        SessionSet set = session.sets().stream()
                .filter(s -> Objects.equals(s.plannedExerciseId(), c.plannedExerciseId())
                        && s.setNumber() == c.setNumber())
                .findFirst()
                .orElseThrow(() -> new SessionSetNotFoundException(setKey));
        Optional<Routine> routine = Optional.ofNullable(session.routineId()).flatMap(routines::findById)
                .filter(r -> r.isOwnedBy(c.userId()));
        Optional<PlannedExercise> planned = routine.flatMap(r -> r.findPlannedExercise(c.plannedExerciseId()));
        boolean alreadyAnswered = calibrations.findBySession(c.sessionId()).stream()
                .anyMatch(r -> Objects.equals(r.plannedExerciseId(), c.plannedExerciseId())
                        && r.setNumber() == c.setNumber());
        boolean needed = planned.map(p -> ExerciseCalibration.needed(p.exercise(),
                sessions.recentCompleted(c.userId(), HISTORY_SESSIONS), now)).orElse(false);
        // Solo la primera serie de un ejercicio que se calibra, en una sesión que no está abandonada: lo demás no es
        // una serie que se calibre (mismo código que una serie que no existe, sin códigos nuevos).
        if (session.isStale(now) || !ExerciseCalibration.accepts(c.setNumber(), needed, alreadyAnswered)) {
            throw new SessionSetNotFoundException(setKey);
        }
        RepRange range = planned.map(p -> p.parameters().repRange()).orElse(null);
        boolean repsMissed = set.failedReps() > 0
                || range != null && set.repsDone() != null && set.repsDone() < range.min();
        // «Usar hoy» (ADR 0031): si la serie fue de otro ejercicio, su material no se conoce y sube lo genérico.
        boolean sameExercise = planned.map(p -> p.exerciseId().equals(set.exerciseId() == null
                ? p.exerciseId() : set.exerciseId())).orElse(false);
        ExerciseCalibration.Result result = ExerciseCalibration.adjust(c.answer(), set.weightKg(),
                sameExercise ? planned.get().exercise().load() : null, repsMissed);
        UUID exerciseId = set.exerciseId() != null ? set.exerciseId() : planned.map(PlannedExercise::exerciseId)
                .orElseThrow(() -> new RoutineExerciseNotFoundException(c.plannedExerciseId()));
        ExerciseCalibrationRecord saved = calibrations.save(new ExerciseCalibrationRecord(UUID.randomUUID(),
                c.userId(), c.sessionId(), c.plannedExerciseId(), exerciseId, c.setNumber(), c.answer(),
                set.weightKg(), result.step(), result.nextWeightKg(), now));
        if (result.nextWeightKg() != null && sameExercise
                && routine.get().applyCalibratedWeight(exerciseId, result.nextWeightKg())) {
            routines.save(routine.get());
        }
        return saved;
    }

    private TrainingSession owned(UUID userId, UUID sessionId) {
        return sessions.findById(sessionId).filter(s -> s.isOwnedBy(userId))
                .orElseThrow(() -> new SessionNotFoundException(sessionId));
    }

    private Optional<RoutineDay> dayOf(TrainingSession session) {
        if (session.routineId() == null || session.dayId() == null) {
            return Optional.empty();
        }
        return routines.findById(session.routineId()).filter(r -> r.isOwnedBy(session.userId()))
                .flatMap(r -> r.findDay(session.dayId()));
    }
}
