package com.synaptixfit.application.service.together;

import com.synaptixfit.application.port.input.together.CreateWorkoutTogetherUseCase;
import com.synaptixfit.application.port.input.together.DeclineWorkoutTogetherUseCase;
import com.synaptixfit.application.port.input.together.FindWorkoutTogetherBySessionUseCase;
import com.synaptixfit.application.port.input.together.GetWorkoutTogetherUseCase;
import com.synaptixfit.application.port.input.together.JoinWorkoutTogetherUseCase;
import com.synaptixfit.application.port.input.together.LeaveWorkoutTogetherUseCase;
import com.synaptixfit.application.port.input.together.StartWorkoutTogetherUseCase;
import com.synaptixfit.application.port.input.together.WorkoutTogetherView;
import com.synaptixfit.application.port.input.training.CopyRoutineForFriendUseCase;
import com.synaptixfit.application.port.input.training.StartTrainingSessionUseCase;
import com.synaptixfit.domain.exception.together.TogetherInvalidStateException;
import com.synaptixfit.domain.exception.together.WorkoutTogetherNotFoundException;
import com.synaptixfit.domain.exception.training.RoutineDayNotFoundException;
import com.synaptixfit.domain.exception.training.RoutineNotFoundException;
import com.synaptixfit.domain.model.shared.Guard;
import com.synaptixfit.domain.model.together.MemberStatus;
import com.synaptixfit.domain.model.together.TogetherMember;
import com.synaptixfit.domain.model.together.WorkoutTogether;
import com.synaptixfit.domain.model.training.PlannedExercise;
import com.synaptixfit.domain.model.training.Routine;
import com.synaptixfit.domain.model.training.RoutineDay;
import com.synaptixfit.domain.model.training.TrainingSession;
import com.synaptixfit.domain.port.output.together.WorkoutTogetherRepositoryPort;
import com.synaptixfit.domain.port.output.training.RoutineRepositoryPort;
import com.synaptixfit.domain.port.output.training.TrainingSessionRepositoryPort;
import java.time.Clock;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.stream.IntStream;

/**
 * «Entrenamos juntos» (ADR 0044): invitar a amigos a un día de la rutina propia para hoy, aceptar, decir que no,
 * salir, empezar y ver por ejercicio quién lo tiene hecho. Cada persona entrena con su sesión normal
 * ({@link StartTrainingSessionUseCase}); quien no es dueño de la rutina recibe una copia en pausa
 * ({@link CopyRoutineForFriendUseCase}), así la sesión en vivo, sus borradores y sus cronómetros son los de siempre.
 */
public class WorkoutTogetherService implements CreateWorkoutTogetherUseCase, GetWorkoutTogetherUseCase,
        FindWorkoutTogetherBySessionUseCase, JoinWorkoutTogetherUseCase, DeclineWorkoutTogetherUseCase,
        LeaveWorkoutTogetherUseCase, StartWorkoutTogetherUseCase {

    private final WorkoutTogetherRepositoryPort workouts;
    private final RoutineRepositoryPort routines;
    private final TrainingSessionRepositoryPort sessions;
    private final CopyRoutineForFriendUseCase copyRoutine;
    private final StartTrainingSessionUseCase startSession;
    private final TogetherPeople people;
    private final TogetherNotifier notifier;
    private final Clock clock;
    private final ZoneId zone;

    public WorkoutTogetherService(WorkoutTogetherRepositoryPort workouts, RoutineRepositoryPort routines,
                                  TrainingSessionRepositoryPort sessions, CopyRoutineForFriendUseCase copyRoutine,
                                  StartTrainingSessionUseCase startSession, TogetherPeople people,
                                  TogetherNotifier notifier, Clock clock, ZoneId zone) {
        this.workouts = workouts;
        this.routines = routines;
        this.sessions = sessions;
        this.copyRoutine = copyRoutine;
        this.startSession = startSession;
        this.people = people;
        this.notifier = notifier;
        this.clock = clock;
        this.zone = zone;
    }

    @Override
    public WorkoutTogetherView create(Command command) {
        Guard.notNull(command, "command");
        Routine routine = routines.findById(command.routineId())
                .filter(r -> r.isOwnedBy(command.userId()) && !r.isDeleted())
                .orElseThrow(() -> new RoutineNotFoundException(command.routineId()));
        RoutineDay day = command.dayId() != null
                ? routine.findDay(command.dayId()).orElseThrow(() -> new RoutineDayNotFoundException(command.dayId()))
                : nextDay(routine);
        if (day.isEmpty()) {
            throw new TogetherInvalidStateException("The day has no exercises");
        }
        WorkoutTogether workout = WorkoutTogether.create(command.userId(), routine.id(), day.id(),
                command.friendIds() == null ? Set.of() : command.friendIds(), today(), clock.instant());
        people.ensureFriends(command.userId(), workout.members().invitedIds());
        WorkoutTogether saved = workouts.save(workout);
        notifier.workoutInvited(saved.members().invitedIds(), command.userId(), saved.id(), routine.name());
        return view(saved, command.userId(), people.lookup());
    }

    @Override
    public WorkoutTogetherView get(UUID userId, UUID workoutId) {
        return view(visible(userId, workoutId), userId, people.lookup());
    }

    @Override
    public Optional<WorkoutTogetherView> bySession(UUID userId, UUID sessionId) {
        return workouts.findBySession(sessionId)
                .filter(w -> w.canView(userId) && w.sessionOf(userId).map(sessionId::equals).orElse(false))
                .map(w -> view(w, userId, people.lookup()));
    }

    @Override
    public WorkoutTogetherView join(UUID userId, UUID workoutId) {
        // Como en los retos: volver tras salir solo si sigue siendo amigo y sin bloqueos con nadie de dentro.
        WorkoutTogether workout = workouts.findById(workoutId)
                .filter(w -> w.members().find(userId).isPresent())
                .filter(w -> people.canJoin(userId, w.hostId(), w.members().joinedIds()))
                .orElseThrow(() -> new WorkoutTogetherNotFoundException(workoutId));
        workout.join(userId, today(), clock.instant());
        return view(workouts.save(workout), userId, people.lookup());
    }

    @Override
    public void decline(UUID userId, UUID workoutId) {
        WorkoutTogether workout = visible(userId, workoutId);
        workout.decline(userId, clock.instant());
        workouts.save(workout);
    }

    @Override
    public void leave(UUID userId, UUID workoutId) {
        WorkoutTogether workout = visible(userId, workoutId);
        if (workout.leave(userId, clock.instant())) {
            workouts.save(workout);
        }
    }

    /**
     * Empieza la sesión de la persona (aceptando la invitación si aún no lo había hecho). Si ya tiene una para este
     * entreno, devuelve esa: volver a tocar «Empezar» retoma, nunca duplica.
     */
    @Override
    public UUID start(UUID userId, UUID workoutId) {
        WorkoutTogether workout = visible(userId, workoutId);
        LocalDate today = today();
        Optional<UUID> existing = workout.sessionOf(userId).filter(id -> sessions.findById(id).isPresent());
        if (existing.isPresent()) {
            return existing.get();
        }
        if (workout.members().find(userId).map(TogetherMember::status).orElse(null) == MemberStatus.INVITED) {
            workout.join(userId, today, clock.instant());
        }
        CopyRoutineForFriendUseCase.Copy target = workout.hostId().equals(userId)
                ? new CopyRoutineForFriendUseCase.Copy(workout.routineId(), workout.dayId())
                : copyRoutine.copyForFriend(workout.routineId(), workout.dayId(), userId);
        TrainingSession session = startSession.start(userId, target.routineId(), target.dayId());
        workout.attachSession(userId, session.id(), today);
        workouts.save(workout);
        return session.id();
    }

    /** Los de hoy en los que la persona está invitada o dentro. */
    List<WorkoutTogetherView> overview(UUID userId, TogetherPeople.Lookup lookup) {
        return workouts.findVisibleTo(userId, today()).stream()
                .filter(w -> w.canView(userId))
                .map(w -> view(w, userId, lookup))
                .toList();
    }

    /** El siguiente día por hacer de la rutina; si ya los cerró todos, el primero con ejercicios. */
    private static RoutineDay nextDay(Routine routine) {
        List<RoutineDay> order = routine.trainableDaysInOrder();
        return order.stream().filter(d -> !d.status().isClosed()).findFirst()
                .or(() -> order.stream().findFirst())
                .orElseThrow(() -> new TogetherInvalidStateException("The routine has no exercises"));
    }

    private WorkoutTogetherView view(WorkoutTogether workout, UUID viewerId, TogetherPeople.Lookup lookup) {
        Optional<Routine> routine = routines.findById(workout.routineId());
        Optional<RoutineDay> day = routine.flatMap(r -> r.findDay(workout.dayId()));
        String routineName = routine.map(Routine::name).orElse(null);
        List<PlannedExercise> planned = day.map(RoutineDay::exercises).orElse(List.of());
        List<WorkoutTogetherView.Slot> slots = IntStream.range(0, planned.size())
                .mapToObj(i -> new WorkoutTogetherView.Slot(i, planned.get(i).exerciseId(),
                        planned.get(i).exercise().name()))
                .toList();
        List<WorkoutTogetherView.Member> members = new ArrayList<>();
        Integer myMinutes = null;
        for (TogetherMember m : workout.members().all()) {
            if (!m.status().canView()) {
                continue;
            }
            Optional<TrainingSession> session = workout.sessionOf(m.userId()).flatMap(sessions::findById);
            WorkoutTogether.MemberState state = session.map(s -> s.isCompleted()
                    ? WorkoutTogether.MemberState.FINISHED : WorkoutTogether.MemberState.TRAINING)
                    .orElse(WorkoutTogether.MemberState.NOT_STARTED);
            List<Integer> done = session.map(this::doneSlots).orElse(List.of());
            members.add(new WorkoutTogetherView.Member(lookup.of(m.userId()), m.status(), state, done,
                    m.userId().equals(viewerId)));
            if (m.userId().equals(viewerId) && session.map(TrainingSession::isCompleted).orElse(false)) {
                myMinutes = session.get().durationMinutes();
            }
        }
        MemberStatus myStatus = workout.members().find(viewerId).map(TogetherMember::status).orElse(MemberStatus.LEFT);
        return new WorkoutTogetherView(workout.id(), lookup.of(workout.hostId()), routineName,
                day.map(RoutineDay::name).orElse(null), day.map(RoutineDay::number).orElse(0), workout.date(),
                workout.isFor(today()), myStatus, workout.sessionOf(viewerId).orElse(null), myMinutes, slots,
                members);
    }

    /** Huecos hechos según el día de la rutina con el que entrena esa persona (la suya o su copia). */
    private List<Integer> doneSlots(TrainingSession session) {
        if (session.routineId() == null || session.dayId() == null) {
            return List.of();
        }
        List<PlannedExercise> own = routines.findById(session.routineId())
                .flatMap(r -> r.findDay(session.dayId()))
                .map(RoutineDay::exercises)
                .orElse(List.of());
        return List.copyOf(WorkoutTogether.doneSlots(own, session.sets()));
    }

    private WorkoutTogether visible(UUID userId, UUID workoutId) {
        return workouts.findById(workoutId)
                .filter(w -> w.canView(userId))
                .orElseThrow(() -> new WorkoutTogetherNotFoundException(workoutId));
    }

    private LocalDate today() {
        return LocalDate.ofInstant(clock.instant(), zone);
    }
}
