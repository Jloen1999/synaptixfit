package com.synaptixfit.application.service.training;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.application.port.input.notification.CreateNotificationUseCase;
import com.synaptixfit.application.port.input.together.CreateWorkoutTogetherUseCase;
import com.synaptixfit.application.port.input.together.WorkoutTogetherView;
import com.synaptixfit.application.port.input.training.CopyRoutineForFriendUseCase;
import com.synaptixfit.application.service.together.TogetherNotifier;
import com.synaptixfit.application.service.together.TogetherPeople;
import com.synaptixfit.application.service.together.WorkoutTogetherService;
import com.synaptixfit.domain.exception.together.TogetherNotFriendsException;
import com.synaptixfit.domain.exception.together.WorkoutTogetherNotFoundException;
import com.synaptixfit.domain.model.shared.Visibility;
import com.synaptixfit.domain.model.social.Friendship;
import com.synaptixfit.domain.model.together.MemberStatus;
import com.synaptixfit.domain.model.together.WorkoutTogether;
import com.synaptixfit.domain.model.training.ExerciseParameters;
import com.synaptixfit.domain.model.training.Routine;
import com.synaptixfit.domain.model.training.RoutineDay;
import com.synaptixfit.domain.model.training.RoutineStatus;
import com.synaptixfit.domain.model.training.RoutineWeek;
import com.synaptixfit.domain.model.training.TrainingGoal;
import com.synaptixfit.domain.model.training.TrainingSession;
import com.synaptixfit.domain.model.training.WeekType;
import com.synaptixfit.domain.model.user.User;
import com.synaptixfit.domain.port.output.social.FriendshipRepositoryPort;
import com.synaptixfit.domain.port.output.together.WorkoutTogetherRepositoryPort;
import com.synaptixfit.domain.port.output.user.UserRepositoryPort;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/**
 * «Entrenamos juntos» (ADR 0044) con dobles en memoria: copia en pausa por posición para quien no es dueño, una sola
 * sesión por persona, quién lleva cada ejercicio y que tras bloquear no se vuelve a entrar.
 */
class WorkoutTogetherFlowTest {

    private static final Instant NOW = Instant.parse("2026-11-16T17:00:00Z");
    private static final Clock CLOCK = Clock.fixed(NOW, ZoneOffset.UTC);

    private final TrainingFakes.Routines routines = new TrainingFakes.Routines();
    private final TrainingFakes.Sessions sessions = new TrainingFakes.Sessions();
    private final Map<UUID, User> users = new HashMap<>();
    private final Map<UUID, Friendship> friendships = new HashMap<>();
    private final Map<UUID, WorkoutTogether> workouts = new HashMap<>();
    private final List<CreateNotificationUseCase.Command> sent = new ArrayList<>();
    /** Lecturas bloqueadas ({@code findByIdForUpdate}) de entrenos, por id. */
    private final List<UUID> locked = new ArrayList<>();
    private RoutineFriendCopyService copy;
    private WorkoutTogetherService service;
    private User host;
    private User ana;
    private Routine routine;
    private RoutineDay monday;
    private RoutineDay thursday;

    @BeforeEach
    void setUp() {
        host = user("Anfitrión");
        ana = user("Ana");
        friendships.put(UUID.randomUUID(), friends(host, ana));
        var bench = TrainingFakes.strength("Press de banca", "Pectoral mayor").toRef();
        var squat = TrainingFakes.strength("Sentadilla", "Cuádriceps").toRef();
        monday = RoutineDay.create(1, "Empuje");
        monday.addExercise(bench, new ExerciseParameters(2, 10, 90, 50.0, null, null, null, null));
        monday.addExercise(squat, new ExerciseParameters(1, 8, 90, 60.0, null, null, null, null));
        thursday = RoutineDay.create(4, null);
        thursday.addExercise(squat, new ExerciseParameters(3, 8, 90, 60.0, null, null, null, null));
        routine = routines.save(Routine.create(host.id(), "Fuerza", null, Visibility.PRIVATE, TrainingGoal.HYPERTROPHY,
                null, null, List.of(RoutineWeek.create(1, null, WeekType.LOAD, List.of(monday, thursday))), NOW));
        copy = new RoutineFriendCopyService(routines, userPort(), CLOCK);
        TogetherPeople people = new TogetherPeople(friendshipPort(), userPort());
        service = new WorkoutTogetherService(workoutPort(), routines, sessions, copy,
                (userId, routineId, dayId) -> sessions.save(TrainingSession.start(userId, routineId, dayId, NOW)),
                people, new TogetherNotifier(c -> {
                    sent.add(c);
                    return Optional.empty();
                }, userPort()), CLOCK, ZoneOffset.UTC);
    }

    @Test
    void theCopyIsPausedKeepsTheDayByPositionAndIsReused() {
        CopyRoutineForFriendUseCase.Copy first = copy.copyForFriend(routine.id(), thursday.id(), ana.id());
        Routine copied = routines.findById(first.routineId()).orElseThrow();
        assertThat(copied.ownerId()).isEqualTo(ana.id());
        assertThat(copied.status()).isEqualTo(RoutineStatus.PAUSED);
        assertThat(copied.origin().ownerName()).isEqualTo("Anfitrión");
        assertThat(copied.findDay(first.dayId()).orElseThrow().number()).isEqualTo(4);
        assertThat(copy.copyForFriend(routine.id(), monday.id(), ana.id()).routineId()).isEqualTo(copied.id());
        assertThat(copy.copyForFriend(routine.id(), monday.id(), host.id()))
                .isEqualTo(new CopyRoutineForFriendUseCase.Copy(routine.id(), monday.id()));
    }

    @Test
    void ifTheOwnerChangedTheDayAfterCopyingItTheNewVersionIsCopied() {
        UUID firstCopy = copy.copyForFriend(routine.id(), monday.id(), ana.id()).routineId();
        Routine changed = routines.findById(routine.id()).orElseThrow();
        changed.findDay(monday.id()).orElseThrow()
                .addExercise(TrainingFakes.strength("Remo", "Dorsal ancho").toRef(),
                        new ExerciseParameters(3, 10, 90, 40.0, null, null, null, null));
        routines.save(changed);

        CopyRoutineForFriendUseCase.Copy second = copy.copyForFriend(routine.id(), monday.id(), ana.id());

        assertThat(second.routineId()).isNotEqualTo(firstCopy);
        assertThat(routines.findById(second.routineId()).orElseThrow().findDay(second.dayId()).orElseThrow()
                .exercises()).hasSize(3);
        assertThat(routines.findById(firstCopy)).isPresent();
    }

    @Test
    void eachOneTrainsWithTheirOwnSessionAndSeesWhoDidEachExercise() {
        WorkoutTogetherView created = service.create(new CreateWorkoutTogetherUseCase.Command(host.id(),
                routine.id(), null, Set.of(ana.id())));
        assertThat(created.exercises()).hasSize(2);
        assertThat(created.dayNumber()).isEqualTo(1);
        assertThat(sent).singleElement().satisfies(c -> assertThat(c.userId()).isEqualTo(ana.id()));

        UUID anaSession = service.start(ana.id(), created.id());
        assertThat(service.start(ana.id(), created.id())).isEqualTo(anaSession);
        TrainingSession session = sessions.findById(anaSession).orElseThrow();
        assertThat(session.routineId()).isNotEqualTo(routine.id());
        RoutineDay anaDay = routines.findById(session.routineId()).orElseThrow().findDay(session.dayId())
                .orElseThrow();
        UUID benchSlot = anaDay.exercises().getFirst().id();
        session.recordSet(benchSlot, 1, 10, 50.0, true, 0);
        session.recordSet(benchSlot, 2, 10, 50.0, true, 0);
        sessions.save(session);

        WorkoutTogetherView seen = service.get(host.id(), created.id());
        WorkoutTogetherView.Member her = seen.members().stream().filter(m -> m.person().id().equals(ana.id()))
                .findFirst().orElseThrow();
        assertThat(her.status()).isEqualTo(MemberStatus.JOINED);
        assertThat(her.state()).isEqualTo(WorkoutTogether.MemberState.TRAINING);
        assertThat(her.doneSlots()).containsExactly(0);
        assertThat(service.bySession(ana.id(), anaSession)).isPresent();
        assertThat(service.bySession(host.id(), anaSession)).isEmpty();
    }

    @Test
    void onlyMutualFriendsAndNoWayBackAfterABlock() {
        User stranger = user("Desconocida");
        assertThatThrownBy(() -> service.create(new CreateWorkoutTogetherUseCase.Command(host.id(), routine.id(),
                null, Set.of(stranger.id())))).isInstanceOf(TogetherNotFriendsException.class);

        WorkoutTogetherView created = service.create(new CreateWorkoutTogetherUseCase.Command(host.id(),
                routine.id(), monday.id(), Set.of(ana.id())));
        service.join(ana.id(), created.id());
        service.leave(ana.id(), created.id());
        service.join(ana.id(), created.id());
        service.leave(ana.id(), created.id());
        friendships.values().forEach(f -> f.blockBy(host.id(), NOW));
        assertThatThrownBy(() -> service.join(ana.id(), created.id()))
                .isInstanceOf(WorkoutTogetherNotFoundException.class);
        assertThatThrownBy(() -> service.get(ana.id(), created.id()))
                .isInstanceOf(WorkoutTogetherNotFoundException.class);
    }

    // ------------------------------------------------------------------ lectura bloqueada (ADR 0045)

    private WorkoutTogetherView invite() {
        return service.create(new CreateWorkoutTogetherUseCase.Command(host.id(), routine.id(), monday.id(),
                Set.of(ana.id())));
    }

    @Test
    void joiningReadsTheWorkoutLocked() {
        WorkoutTogetherView w = invite();
        locked.clear();
        service.join(ana.id(), w.id());
        assertThat(locked).containsExactly(w.id());
    }

    @Test
    void decliningReadsTheWorkoutLocked() {
        WorkoutTogetherView w = invite();
        locked.clear();
        service.decline(ana.id(), w.id());
        assertThat(locked).containsExactly(w.id());
    }

    @Test
    void leavingReadsTheWorkoutLocked() {
        WorkoutTogetherView w = invite();
        service.join(ana.id(), w.id());
        locked.clear();
        service.leave(ana.id(), w.id());
        assertThat(locked).containsExactly(w.id());
    }

    @Test
    void startingReadsTheWorkoutLocked() {
        WorkoutTogetherView w = invite();
        locked.clear();
        service.start(ana.id(), w.id());
        assertThat(locked).containsExactly(w.id());
    }

    private User user(String name) {
        User u = User.builder().id(UUID.randomUUID()).email(UUID.randomUUID() + "@example.com").fullName(name)
                .passwordHash("h").privacy(Visibility.FRIENDS).createdAt(NOW).build();
        users.put(u.id(), u);
        return u;
    }

    private static Friendship friends(User a, User b) {
        Friendship f = Friendship.request(a.id(), b.id(), NOW);
        f.accept(b.id(), NOW);
        return f;
    }

    private UserRepositoryPort userPort() {
        return new UserRepositoryPort() {
            public Optional<User> findById(UUID id) { return Optional.ofNullable(users.get(id)); }
            public Optional<User> findByEmail(String e) { return Optional.empty(); }
            public Optional<User> findByGoogleSubject(String s) { return Optional.empty(); }
            public boolean existsByEmail(String e) { return false; }
            public User save(User u) { users.put(u.id(), u); return u; }
        };
    }

    private FriendshipRepositoryPort friendshipPort() {
        return new FriendshipRepositoryPort() {
            public Optional<Friendship> findById(UUID id) { return Optional.ofNullable(friendships.get(id)); }
            public Optional<Friendship> findBetween(UUID a, UUID b) {
                return friendships.values().stream().filter(f -> f.involves(a) && f.involves(b)).findFirst();
            }
            public Friendship save(Friendship f) { friendships.put(f.id(), f); return f; }
            public void delete(UUID id) { friendships.remove(id); }
        };
    }

    private WorkoutTogetherRepositoryPort workoutPort() {
        return new WorkoutTogetherRepositoryPort() {
            public Optional<WorkoutTogether> findById(UUID id) { return Optional.ofNullable(workouts.get(id)); }
            public Optional<WorkoutTogether> findByIdForUpdate(UUID id) {
                locked.add(id);
                return findById(id);
            }
            public WorkoutTogether save(WorkoutTogether w) { workouts.put(w.id(), w); return w; }
            public List<WorkoutTogether> findVisibleTo(UUID u, LocalDate from) {
                return workouts.values().stream().filter(w -> w.canView(u)).toList();
            }
            public Optional<WorkoutTogether> findBySession(UUID s) {
                return workouts.values().stream().filter(w -> w.sessions().containsValue(s)).findFirst();
            }
        };
    }
}
