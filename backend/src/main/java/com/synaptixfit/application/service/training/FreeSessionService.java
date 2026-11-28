package com.synaptixfit.application.service.training;

import com.synaptixfit.application.port.input.training.AddSessionExerciseUseCase;
import com.synaptixfit.application.port.input.training.CreateRoutineUseCase;
import com.synaptixfit.application.port.input.training.GetStartingLoadsUseCase;
import com.synaptixfit.application.port.input.training.RoutineStructureInput;
import com.synaptixfit.application.port.input.training.SaveSessionAsRoutineUseCase;
import com.synaptixfit.application.port.input.training.StartFreeSessionUseCase;
import com.synaptixfit.domain.exception.training.ExerciseNotFoundException;
import com.synaptixfit.domain.exception.training.RoutineDayNotFoundException;
import com.synaptixfit.domain.exception.training.RoutineTemplateNotFoundException;
import com.synaptixfit.domain.exception.training.SessionNotFoundException;
import com.synaptixfit.domain.exception.training.SessionNothingToRepeatException;
import com.synaptixfit.domain.exception.training.SessionNothingToSaveException;
import com.synaptixfit.domain.model.shared.Visibility;
import com.synaptixfit.domain.model.training.Exercise;
import com.synaptixfit.domain.model.training.ExerciseRef;
import com.synaptixfit.domain.model.training.FreeSessionPlan;
import com.synaptixfit.domain.model.training.PlannedExercise;
import com.synaptixfit.domain.model.training.Routine;
import com.synaptixfit.domain.model.training.RoutineDay;
import com.synaptixfit.domain.model.training.RoutineTemplate;
import com.synaptixfit.domain.model.training.TemplateLevel;
import com.synaptixfit.domain.model.training.TrainingGoal;
import com.synaptixfit.domain.model.training.TrainingSession;
import com.synaptixfit.domain.model.training.TrainingSession.FreeExercise;
import com.synaptixfit.domain.model.training.WeekType;
import com.synaptixfit.domain.port.output.training.ExerciseRepositoryPort;
import com.synaptixfit.domain.port.output.training.RoutineRepositoryPort;
import com.synaptixfit.domain.port.output.training.RoutineTemplateRepositoryPort;
import com.synaptixfit.domain.port.output.training.TrainingSessionRepositoryPort;
import java.time.Clock;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

/**
 * Sesión libre con ejercicios (ADR 0067): la empieza con su lista (elegidos, repetir una sesión o un día de
 * plantilla), suma ejercicios sobre la marcha y la guarda como rutina. Terminarla es lo mismo que cualquier sesión
 * ({@link TrainingSessionService}): racha, XP, carga, retos y semana salen de ahí, sin reglas aparte.
 */
public class FreeSessionService implements StartFreeSessionUseCase, AddSessionExerciseUseCase,
        SaveSessionAsRoutineUseCase {

    private final TrainingSessionRepositoryPort sessions;
    private final RoutineRepositoryPort routines;
    private final ExerciseRepositoryPort exercises;
    private final RoutineTemplateRepositoryPort templates;
    private final GetStartingLoadsUseCase startingLoads;
    private final CreateRoutineUseCase createRoutine;
    private final Clock clock;
    private final ZoneId zone;

    public FreeSessionService(TrainingSessionRepositoryPort sessions, RoutineRepositoryPort routines,
                              ExerciseRepositoryPort exercises, RoutineTemplateRepositoryPort templates,
                              GetStartingLoadsUseCase startingLoads, CreateRoutineUseCase createRoutine, Clock clock,
                              ZoneId zone) {
        this.sessions = sessions;
        this.routines = routines;
        this.exercises = exercises;
        this.templates = templates;
        this.startingLoads = startingLoads;
        this.createRoutine = createRoutine;
        this.clock = clock;
        this.zone = zone;
    }

    @Override
    public TrainingSession startFree(StartFreeSessionUseCase.Command c) {
        List<FreeExercise> plan;
        if (c.fromSessionId() != null) {
            plan = repeating(c.userId(), c.fromSessionId());
        } else if (c.templateId() != null) {
            plan = fromTemplateDay(c.userId(), c.templateId(), c.templateDayNumber(), c.language());
        } else {
            plan = chosen(c.userId(), c.exerciseIds());
        }
        return sessions.save(TrainingSession.startFree(c.userId(), clock.instant(), plan));
    }

    @Override
    public TrainingSession addExercise(UUID userId, UUID sessionId, UUID exerciseId) {
        TrainingSession session = owned(userId, sessionId);
        if (session.freeExercises().stream().anyMatch(p -> p.exerciseId().equals(exerciseId))) {
            return session;
        }
        chosen(userId, List.of(exerciseId)).forEach(e -> session.addFreeExercise(e.exercise(), e.parameters()));
        return sessions.save(session);
    }

    @Override
    public Routine saveAsRoutine(UUID userId, UUID sessionId, String name) {
        TrainingSession session = owned(userId, sessionId);
        List<FreeExercise> done = session.dayId() != null ? List.of()
                : FreeSessionPlan.performed(session.freeExercises(), session.sets(), this::activeRef);
        if (done.isEmpty()) {
            throw new SessionNothingToSaveException();
        }
        // Un día, el de la semana en que se entrenó: la rutina se puede repartir después en el editor.
        LocalDate day = LocalDate.ofInstant(session.startedAt(), zone);
        RoutineStructureInput.Day routineDay = new RoutineStructureInput.Day(day.getDayOfWeek().getValue(), null,
                done.stream().map(e -> new RoutineStructureInput.Exercise(e.exercise().id(), e.parameters()))
                        .toList());
        return createRoutine.create(new CreateRoutineUseCase.Command(userId, name, null, Visibility.PRIVATE,
                TrainingGoal.HYPERTROPHY, null, List.of(new RoutineStructureInput.Week(null, null,
                List.of(routineDay)))));
    }

    /** Lo que se hizo en una sesión propia, con sus cifras de verdad. */
    private List<FreeExercise> repeating(UUID userId, UUID fromSessionId) {
        TrainingSession previous = owned(userId, fromSessionId);
        List<PlannedExercise> slots = previous.dayId() == null ? previous.freeExercises()
                : routines.findById(previous.routineId()).flatMap(r -> r.findDay(previous.dayId()))
                        .map(RoutineDay::exercises).orElse(List.of());
        List<FreeExercise> plan = FreeSessionPlan.performed(slots, previous.sets(), this::activeRef).stream()
                .filter(e -> e.exercise().active()).toList();
        if (plan.isEmpty()) {
            throw new SessionNothingToRepeatException();
        }
        return plan;
    }

    /** Un día de una plantilla ofrecida, con las cifras de su primera semana y el peso de partida de cada uno. */
    private List<FreeExercise> fromTemplateDay(UUID userId, UUID templateId, Integer dayNumber, String language) {
        RoutineTemplate template = templates.findById(templateId, language).filter(RoutineTemplate::active)
                .orElseThrow(() -> new RoutineTemplateNotFoundException(templateId));
        RoutineTemplate.Day day = template.days().stream()
                .filter(d -> dayNumber != null && d.dayNumber() == dayNumber).findFirst()
                .orElseThrow(() -> new RoutineDayNotFoundException(templateId));
        List<UUID> ids = day.exercises().stream().map(RoutineTemplate.Item::exerciseId).toList();
        Map<UUID, Double> weights = startingLoads.startingLoads(userId, ids, template.level());
        WeekType firstWeek = WeekType.forPosition(1, template.weeks());
        return day.exercises().stream()
                .flatMap(item -> activeRef(item.exerciseId()).stream()
                        .map(ref -> new FreeExercise(ref,
                                RoutineTemplate.parametersFor(item, firstWeek, weights.get(item.exerciseId())))))
                .toList();
    }

    /** Ejercicios elegidos (sin repetir), con las cifras de partida de cada uno según cómo se mide. */
    private List<FreeExercise> chosen(UUID userId, List<UUID> exerciseIds) {
        List<UUID> ids = exerciseIds.stream().distinct().toList();
        List<ExerciseRef> refs = ids.stream()
                .map(id -> activeRef(id).orElseThrow(() -> new ExerciseNotFoundException(id))).toList();
        Map<UUID, Double> weights = ids.isEmpty() ? Map.of()
                : startingLoads.startingLoads(userId, ids, TemplateLevel.BEGINNER);
        return refs.stream().map(r -> new FreeExercise(r, FreeSessionPlan.startingFor(r, weights.get(r.id()))))
                .toList();
    }

    private Optional<ExerciseRef> activeRef(UUID exerciseId) {
        return exercises.findById(exerciseId).filter(Exercise::active).map(Exercise::toRef);
    }

    private TrainingSession owned(UUID userId, UUID sessionId) {
        return sessions.findById(sessionId).filter(s -> s.isOwnedBy(userId))
                .orElseThrow(() -> new SessionNotFoundException(sessionId));
    }
}
