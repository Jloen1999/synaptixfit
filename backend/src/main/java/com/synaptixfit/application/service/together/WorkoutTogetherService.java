package com.synaptixfit.application.service.together;

import com.synaptixfit.application.port.input.together.CreateWorkoutTogetherUseCase;
import com.synaptixfit.application.port.input.together.DeclineWorkoutTogetherUseCase;
import com.synaptixfit.application.port.input.together.FindWorkoutTogetherBySessionUseCase;
import com.synaptixfit.application.port.input.together.GetWorkoutTogetherUseCase;
import com.synaptixfit.application.port.input.together.JoinWorkoutTogetherUseCase;
import com.synaptixfit.application.port.input.together.LeaveWorkoutTogetherUseCase;
import com.synaptixfit.application.port.input.together.NotifyWorkoutTogetherProgressUseCase;
import com.synaptixfit.application.port.input.together.PauseWorkoutTogetherUseCase;
import com.synaptixfit.application.port.input.together.ResumeWorkoutTogetherUseCase;
import com.synaptixfit.application.port.input.together.StartWorkoutTogetherUseCase;
import com.synaptixfit.application.port.input.together.WorkoutTogetherView;
import com.synaptixfit.application.port.input.training.CopyRoutineForFriendUseCase;
import com.synaptixfit.application.port.input.training.PauseTrainingSessionUseCase;
import com.synaptixfit.application.port.input.training.ResumeTrainingSessionUseCase;
import com.synaptixfit.application.port.input.training.StartTrainingSessionUseCase;
import com.synaptixfit.domain.exception.together.TogetherInvalidStateException;
import com.synaptixfit.domain.exception.together.WorkoutTogetherNotFoundException;
import com.synaptixfit.domain.exception.training.RoutineDayNotFoundException;
import com.synaptixfit.domain.exception.training.RoutineNotFoundException;
import com.synaptixfit.domain.model.shared.Guard;
import com.synaptixfit.domain.model.together.MemberStatus;
import com.synaptixfit.domain.model.together.TogetherLiveChange;
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
import java.time.Instant;
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
 *
 * <p>A la vez (ADR 0047): «Empezar» crea la sesión de todas las personas de dentro con la misma hora de inicio, y
 * pausar o reanudar una de esas sesiones pausa o reanuda las de todos con los casos de uso de siempre (ADR 0030).
 * Cada cambio se avisa en directo al grupo con {@link TogetherNotifier}.
 */
@SuppressWarnings("java:S107")
public class WorkoutTogetherService implements CreateWorkoutTogetherUseCase, GetWorkoutTogetherUseCase,
        FindWorkoutTogetherBySessionUseCase, JoinWorkoutTogetherUseCase, DeclineWorkoutTogetherUseCase,
        LeaveWorkoutTogetherUseCase, StartWorkoutTogetherUseCase, PauseWorkoutTogetherUseCase,
        ResumeWorkoutTogetherUseCase, NotifyWorkoutTogetherProgressUseCase {

    private final WorkoutTogetherRepositoryPort workouts;
    private final RoutineRepositoryPort routines;
    private final TrainingSessionRepositoryPort sessions;
    private final CopyRoutineForFriendUseCase copyRoutine;
    private final StartTrainingSessionUseCase startSession;
    private final PauseTrainingSessionUseCase pauseSession;
    private final ResumeTrainingSessionUseCase resumeSession;
    private final TogetherPeople people;
    private final TogetherNotifier notifier;
    private final Clock clock;
    private final ZoneId zone;

    public WorkoutTogetherService(WorkoutTogetherRepositoryPort workouts, RoutineRepositoryPort routines,
                                  TrainingSessionRepositoryPort sessions, CopyRoutineForFriendUseCase copyRoutine,
                                  StartTrainingSessionUseCase startSession, PauseTrainingSessionUseCase pauseSession,
                                  ResumeTrainingSessionUseCase resumeSession, TogetherPeople people,
                                  TogetherNotifier notifier, Clock clock, ZoneId zone) {
        this.workouts = workouts;
        this.routines = routines;
        this.sessions = sessions;
        this.copyRoutine = copyRoutine;
        this.startSession = startSession;
        this.pauseSession = pauseSession;
        this.resumeSession = resumeSession;
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
        notifier.changed(TogetherLiveChange.Topic.TOGETHER, saved.id(), saved.audience(command.userId()));
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
        WorkoutTogether workout = workouts.findByIdForUpdate(workoutId)
                .filter(w -> w.members().find(userId).isPresent())
                .filter(w -> people.canJoin(userId, w.hostId(), w.members().joinedIds()))
                .orElseThrow(() -> new WorkoutTogetherNotFoundException(workoutId));
        Instant now = clock.instant();
        workout.join(userId, today(), now);
        if (workout.isStarted()) {
            // Llega tarde: entra con su sesión desde este momento (y en pausa si el grupo lo está). Con una sesión
            // abandonada de ese día no se le crea: aceptar no falla y «Empezar» le muestra la pregunta de siempre.
            startSessionFor(workout, userId, now, true);
        }
        WorkoutTogether saved = workouts.save(workout);
        changed(saved, userId);
        return view(saved, userId, people.lookup());
    }

    @Override
    public void decline(UUID userId, UUID workoutId) {
        WorkoutTogether workout = visibleForUpdate(userId, workoutId);
        workout.decline(userId, clock.instant());
        changed(workouts.save(workout), userId);
    }

    @Override
    public void leave(UUID userId, UUID workoutId) {
        WorkoutTogether workout = visibleForUpdate(userId, workoutId);
        if (workout.leave(userId, clock.instant())) {
            changed(workouts.save(workout), userId);
        }
    }

    /**
     * La primera vez empieza para todo el grupo (ADR 0047): la sesión normal de cada persona de dentro, con la misma
     * hora de inicio, en esta misma transacción. El entreno se lee bloqueado y se comprueba que no había empezado,
     * así dos «Empezar» a la vez no crean dos sesiones ni dos horas de inicio. Después, «Empezar» retoma la sesión de
     * quien lo pulsa (o se la crea desde ese momento si le faltaba). Nunca duplica.
     */
    @Override
    public UUID start(UUID userId, UUID workoutId) {
        WorkoutTogether workout = visibleForUpdate(userId, workoutId);
        LocalDate today = today();
        Instant now = clock.instant();
        if (workout.members().find(userId).map(TogetherMember::status).orElse(null) == MemberStatus.INVITED) {
            // Como «Unirme»: solo si sigue siendo amigo de quien invita y sin bloqueos con nadie de dentro.
            if (!people.canJoin(userId, workout.hostId(), workout.members().joinedIds())) {
                throw new WorkoutTogetherNotFoundException(workoutId);
            }
            workout.join(userId, today, now);
        }
        Optional<UUID> mine;
        if (workout.start(userId, today, now)) {
            for (UUID member : workout.members().joinedIds()) {
                // A quien pulsa se le crea siempre (si tiene una sesión abandonada de ese día, ve su aviso de siempre);
                // a los demás, solo si se puede sin preguntarles (ver startSessionFor).
                startSessionFor(workout, member, now, !member.equals(userId));
            }
            mine = workout.sessionOf(userId);
        } else {
            mine = workout.sessionOf(userId).filter(id -> sessions.findById(id).isPresent())
                    .or(() -> joinRunning(workout, userId, now));
        }
        WorkoutTogether saved = workouts.save(workout);
        changed(saved, userId);
        return mine.orElseThrow(() -> new TogetherInvalidStateException("No session could be started"));
    }

    @Override
    public void pauseFromSession(UUID userId, UUID sessionId, Instant pausedAt) {
        Optional<WorkoutTogether> found = lockedBySession(userId, sessionId);
        if (found.isEmpty() || !found.get().pause(userId, pausedAt)) {
            return;
        }
        WorkoutTogether workout = workouts.save(found.get());
        // El grupo ya consta en pausa antes de pausar a los demás: la pausa de cada sesión vuelve a llegar aquí
        // (TrainingSessionPauseChanged) y no hace nada.
        workout.joinedSessionsExcept(userId).forEach((member, session) -> sessions.findById(session)
                .filter(s -> !s.isCompleted() && !s.isPaused())
                .ifPresent(s -> pauseSession.pause(member, session)));
        changed(workout, userId);
    }

    @Override
    public void resumeFromSession(UUID userId, UUID sessionId, Instant resumedAt) {
        Optional<WorkoutTogether> found = lockedBySession(userId, sessionId);
        if (found.isEmpty() || !found.get().resume(userId)) {
            return;
        }
        WorkoutTogether workout = workouts.save(found.get());
        workout.joinedSessionsExcept(userId).forEach((member, session) -> sessions.findById(session)
                .filter(s -> !s.isCompleted() && s.isPaused())
                .ifPresent(s -> resumeSession.resume(member, session, resumedAt)));
        changed(workout, userId);
    }

    @Override
    public void sessionProgressed(UUID userId, UUID sessionId) {
        workouts.findBySession(sessionId)
                .filter(w -> w.sessionOf(userId).map(sessionId::equals).orElse(false))
                .ifPresent(w -> changed(w, userId));
    }

    /**
     * Crea la sesión del grupo de {@code member} con la hora común. Si ya tenía una abierta de ese mismo día, la usa.
     * Con {@code skipIfStale}, a quien tiene una sesión abandonada de ese día no se le crea (habría que preguntarle si
     * terminarla o descartarla): entra después con «Ir», que le muestra esa pregunta. Las demás sesiones abiertas que
     * tuviera se ponen en pausa, no se terminan ni se descartan: así no cuentan como entrenadas mientras entrena con
     * el grupo y decide él qué hacer con ellas (ADR 0047).
     */
    private Optional<UUID> startSessionFor(WorkoutTogether workout, UUID member, Instant startedAt,
                                           boolean skipIfStale) {
        Optional<UUID> existing = workout.sessionOf(member).filter(id -> sessions.findById(id).isPresent());
        if (existing.isPresent()) {
            return existing;
        }
        Instant now = clock.instant();
        CopyRoutineForFriendUseCase.Copy target = workout.hostId().equals(member)
                ? new CopyRoutineForFriendUseCase.Copy(workout.routineId(), workout.dayId())
                : copyRoutine.copyForFriend(workout.routineId(), workout.dayId(), member);
        if (skipIfStale && sessions.findInProgressForDay(member, target.dayId()).filter(s -> s.isStale(now))
                .isPresent()) {
            return Optional.empty();
        }
        TrainingSession session = startSession.start(member, target.routineId(), target.dayId(), startedAt);
        workout.attachSession(member, session.id(), today());
        // Una sesión de otro entreno juntos no se toca: pausarla pausaría a todo ese otro grupo.
        sessions.findOpen(member).stream()
                .filter(s -> !s.id().equals(session.id()) && !s.isStale(now) && !s.isPaused())
                .filter(s -> workouts.findBySession(s.id()).isEmpty())
                .forEach(s -> pauseSession.pause(member, s.id()));
        if (workout.isPaused() && !session.isPaused()) {
            pauseSession.pause(member, session.id());
        }
        return Optional.of(session.id());
    }

    /** Quien entra (o pulsa «Empezar») con el entreno ya en marcha: su sesión empieza ahora, no a la hora común. */
    private Optional<UUID> joinRunning(WorkoutTogether workout, UUID member, Instant now) {
        return startSessionFor(workout, member, now, false);
    }

    /** El entreno juntos de esa sesión de {@code userId}, bloqueado, si es de hoy. */
    private Optional<WorkoutTogether> lockedBySession(UUID userId, UUID sessionId) {
        return workouts.findBySession(sessionId)
                .filter(w -> w.sessionOf(userId).map(sessionId::equals).orElse(false))
                .flatMap(w -> workouts.findByIdForUpdate(w.id()))
                .filter(w -> w.isFor(today()) && w.sessionOf(userId).map(sessionId::equals).orElse(false));
    }

    /** Aviso en directo al grupo y a quien actuó (ADR 0047). */
    private void changed(WorkoutTogether workout, UUID actorId) {
        notifier.changed(TogetherLiveChange.Topic.WORKOUT, workout.id(), workout.audience(actorId));
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
                members, workout.startedAt(),
                workout.startedBy() == null ? null : lookup.of(workout.startedBy()), workout.pausedAt(),
                workout.pausedBy() == null ? null : lookup.of(workout.pausedBy()));
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

    /** Como {@link #visible}, pero bloqueado: para las acciones que lo cambian (ADR 0045). */
    private WorkoutTogether visibleForUpdate(UUID userId, UUID workoutId) {
        return workouts.findByIdForUpdate(workoutId)
                .filter(w -> w.canView(userId))
                .orElseThrow(() -> new WorkoutTogetherNotFoundException(workoutId));
    }

    private LocalDate today() {
        return LocalDate.ofInstant(clock.instant(), zone);
    }
}
