package com.synaptixfit.application.service.together;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.assertj.core.groups.Tuple.tuple;

import com.synaptixfit.application.port.input.notification.CreateNotificationUseCase;
import com.synaptixfit.application.port.input.planner.RecordFocusSessionUseCase;
import com.synaptixfit.application.port.input.together.CreateStudyRoomUseCase;
import com.synaptixfit.application.port.input.together.StudyRoomView;
import com.synaptixfit.domain.exception.planner.PlannerSubjectNotFoundException;
import com.synaptixfit.domain.exception.together.StudyRoomNotFoundException;
import com.synaptixfit.domain.exception.together.TogetherNotFriendsException;
import com.synaptixfit.domain.model.notification.NotificationMessage;
import com.synaptixfit.domain.model.planner.FocusSession;
import com.synaptixfit.domain.model.planner.PlannerZone;
import com.synaptixfit.domain.model.planner.SubjectRef;
import com.synaptixfit.domain.model.shared.Visibility;
import com.synaptixfit.domain.model.social.Friendship;
import com.synaptixfit.domain.model.together.FriendChallenge;
import com.synaptixfit.domain.model.together.FriendStreak;
import com.synaptixfit.domain.model.together.MemberStatus;
import com.synaptixfit.domain.model.together.StudyRoom;
import com.synaptixfit.domain.model.together.StudyRoomLength;
import com.synaptixfit.domain.model.together.StudyRoomReaction;
import com.synaptixfit.domain.model.together.WorkoutTogether;
import com.synaptixfit.domain.model.user.User;
import com.synaptixfit.domain.port.output.planner.SubjectDirectoryPort;
import com.synaptixfit.domain.port.output.social.FriendshipRepositoryPort;
import com.synaptixfit.domain.port.output.together.FriendChallengeRepositoryPort;
import com.synaptixfit.domain.port.output.together.FriendStreakRepositoryPort;
import com.synaptixfit.domain.port.output.together.WorkoutTogetherRepositoryPort;
import com.synaptixfit.domain.port.output.user.UserRepositoryPort;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/**
 * «Estudiamos juntos» (ADR 0045) con dobles en memoria: solo amigos mutuos, cada ronda cuenta como un Pomodoro normal
 * para quien estaba dentro (una sola vez), la asignatura de cada uno es privada y bloquear saca de la sala.
 */
class StudyRoomServiceTest {

    private static final ZoneId UTC = ZoneOffset.UTC;
    private static final Instant START = Instant.parse("2026-11-18T16:00:00Z");

    private final MutableClock clock = new MutableClock(START);
    private final Map<UUID, User> users = new HashMap<>();
    private final Map<UUID, Friendship> friendships = new HashMap<>();
    private final Map<UUID, Set<UUID>> ownSubjects = new HashMap<>();
    private final List<RecordFocusSessionUseCase.Command> recorded = new ArrayList<>();
    private final List<CreateNotificationUseCase.Command> sent = new ArrayList<>();
    private final InMemoryStudyRooms rooms = new InMemoryStudyRooms();

    private StudyRoomService service;
    private TogetherPeople people;
    private User me;
    private User ana;
    private User luis;

    @BeforeEach
    void setUp() {
        me = user("Yo");
        ana = user("Ana");
        luis = user("Luis");
        friends(me, ana);
        friends(me, luis);
        people = new TogetherPeople(friendshipPort(), userPort());
        TogetherNotifier notifier = new TogetherNotifier(c -> {
            sent.add(c);
            return Optional.empty();
        }, userPort());
        RecordFocusSessionUseCase record = c -> {
            recorded.add(c);
            return new RecordFocusSessionUseCase.Result(null, null);
        };
        service = new StudyRoomService(rooms, subjectPort(), record, people, notifier, clock, new PlannerZone(UTC));
    }

    private StudyRoomView create(UUID subjectId, User... friends) {
        Set<UUID> ids = new HashSet<>();
        for (User f : friends) {
            ids.add(f.id());
        }
        return service.create(new CreateStudyRoomUseCase.Command(me.id(), StudyRoomLength.SHORT, 2, ids, subjectId));
    }

    @Test
    void onlyMutualFriendsAreInvitedAndTheyGetANotice() {
        User stranger = user("Desconocida");
        assertThatThrownBy(() -> create(null, stranger)).isInstanceOf(TogetherNotFriendsException.class);
        UUID foreignSubject = UUID.randomUUID();
        ownSubjects.put(ana.id(), Set.of(foreignSubject));
        assertThatThrownBy(() -> create(foreignSubject, ana)).isInstanceOf(PlannerSubjectNotFoundException.class);
        assertThat(rooms.rooms).isEmpty();

        StudyRoomView room = create(null, ana, luis);
        assertThat(room.phase()).isEqualTo(StudyRoom.Phase.WAITING);
        assertThat(room.myStatus()).isEqualTo(MemberStatus.JOINED);
        assertThat(room.serverTime()).isEqualTo(START);
        assertThat(room.members()).first().satisfies(m -> assertThat(m.me()).isTrue());
        assertThat(sent).hasSize(2).allSatisfy(c -> {
            assertThat(c.message().code()).isEqualTo(NotificationMessage.Code.STUDY_ROOM_INVITED);
            assertThat(c.actionUrl()).isEqualTo("/social/together/study/" + room.id());
        });
    }

    @Test
    void eachFinishedRoundIsAPomodoroForEveryoneInsideOnlyOnce() {
        UUID algebra = subject(me);
        UUID history = subject(ana);
        StudyRoomView room = create(algebra, ana, luis);
        service.join(ana.id(), room.id());
        service.chooseSubject(ana.id(), room.id(), history);
        service.start(ana.id(), room.id());
        clock.advance(Duration.ofMinutes(10));
        service.join(luis.id(), room.id());

        clock.advance(Duration.ofMinutes(16));
        assertThat(service.roomsToCredit()).containsExactly(room.id());
        assertThat(service.creditRounds(room.id())).isEqualTo(3);
        assertThat(service.creditRounds(room.id())).isZero();
        LocalDate today = LocalDate.ofInstant(START, UTC);
        assertThat(recorded).extracting(RecordFocusSessionUseCase.Command::userId,
                        RecordFocusSessionUseCase.Command::durationMinutes, RecordFocusSessionUseCase.Command::subjectId)
                .containsExactlyInAnyOrder(
                        tuple(me.id(), 25, algebra),
                        tuple(ana.id(), 25, history),
                        tuple(luis.id(), 15, null));
        assertThat(recorded).allSatisfy(c -> {
            assertThat(c.phase()).isEqualTo(FocusSession.FocusPhase.FOCUS);
            assertThat(c.completed()).isTrue();
            assertThat(c.date()).isEqualTo(today);
        });
    }

    @Test
    void whenAnotherRequestClaimedTheRoundsNothingIsRecordedTwice() {
        StudyRoomView room = create(null, ana);
        service.start(me.id(), room.id());
        clock.advance(Duration.ofMinutes(26));
        rooms.claimsWin = false;
        assertThat(service.creditRounds(room.id())).isZero();
        service.leave(me.id(), room.id());
        assertThat(recorded).isEmpty();
    }

    @Test
    void leavingCountsWhatFinishedBeforeAndTheOthersGoOn() {
        StudyRoomView room = create(null, ana);
        service.join(ana.id(), room.id());
        service.start(me.id(), room.id());
        clock.advance(Duration.ofMinutes(40));
        // Salir no apunta nada (un fallo al apuntar nunca impide salir): la ronda 1, terminada con la persona
        // dentro, la apunta el programador después, también a quien ya se fue.
        service.leave(me.id(), room.id());
        assertThat(recorded).isEmpty();
        assertThat(service.creditRounds(room.id())).isEqualTo(2);
        assertThat(recorded).extracting(RecordFocusSessionUseCase.Command::userId)
                .containsExactlyInAnyOrder(me.id(), ana.id());
        assertThatThrownBy(() -> service.get(me.id(), room.id())).isInstanceOf(StudyRoomNotFoundException.class);

        StudyRoomView hers = service.get(ana.id(), room.id());
        assertThat(hers.phase()).isEqualTo(StudyRoom.Phase.FOCUS);
        assertThat(hers.round()).isEqualTo(2);
        assertThat(hers.members()).anySatisfy(m -> {
            assertThat(m.person().id()).isEqualTo(me.id());
            assertThat(m.status()).isEqualTo(MemberStatus.LEFT);
        });

        clock.advance(Duration.ofMinutes(20));
        recorded.clear();
        service.creditRounds(room.id());
        assertThat(recorded).extracting(RecordFocusSessionUseCase.Command::userId).containsExactly(ana.id());
    }

    @Test
    void undoAfterLeavingComesBackWhileTheRoomIsOn() {
        StudyRoomView room = create(null, ana);
        service.leave(me.id(), room.id());
        StudyRoomView back = service.join(me.id(), room.id());
        assertThat(back.myStatus()).isEqualTo(MemberStatus.JOINED);
    }

    @Test
    void theSubjectOfEachPersonIsOnlyTheirsAndReactionsFade() {
        UUID algebra = subject(me);
        StudyRoomView room = create(algebra, ana);
        service.join(ana.id(), room.id());
        assertThat(service.get(me.id(), room.id()).mySubjectId()).isEqualTo(algebra);
        assertThat(service.get(ana.id(), room.id()).mySubjectId()).isNull();

        service.react(ana.id(), room.id(), StudyRoomReaction.FIRE);
        assertThat(service.get(me.id(), room.id()).members())
                .filteredOn(m -> m.person().id().equals(ana.id())).singleElement()
                .satisfies(m -> assertThat(m.reaction()).isEqualTo(StudyRoomReaction.FIRE));
        clock.advance(StudyRoom.REACTION_SHOWN);
        assertThat(service.get(me.id(), room.id()).members()).allSatisfy(m -> assertThat(m.reaction()).isNull());
    }

    @Test
    void aDeletedSubjectStillCountsTheRoundWithoutIt() {
        UUID algebra = subject(me);
        StudyRoomView room = create(algebra, ana);
        service.start(me.id(), room.id());
        ownSubjects.get(me.id()).remove(algebra);
        clock.advance(Duration.ofMinutes(25));
        service.creditRounds(room.id());
        assertThat(recorded).singleElement().satisfies(c -> assertThat(c.subjectId()).isNull());
    }

    @Test
    void overviewHidesRoomsThatAreOverAndBlockingTakesThePersonOut() {
        StudyRoomView room = create(null, ana, luis);
        service.join(ana.id(), room.id());
        service.join(luis.id(), room.id());
        assertThat(service.overview(ana.id(), people.lookup())).hasSize(1);

        new TogetherCleanupService(new EmptyStreaks(), new EmptyChallenges(), new EmptyWorkouts(), service, clock, UTC)
                .leaveShared(me.id(), ana.id(), true);
        assertThatThrownBy(() -> service.get(ana.id(), room.id())).isInstanceOf(StudyRoomNotFoundException.class);
        assertThat(service.get(luis.id(), room.id()).myStatus()).isEqualTo(MemberStatus.JOINED);

        clock.advance(StudyRoom.WAITING_LIMIT);
        assertThat(service.overview(luis.id(), people.lookup())).isEmpty();
    }

    // ------------------------------------------------------------------ dobles

    private UUID subject(User owner) {
        UUID id = UUID.randomUUID();
        ownSubjects.computeIfAbsent(owner.id(), k -> new HashSet<>()).add(id);
        return id;
    }

    private User user(String name) {
        User u = User.builder().id(UUID.randomUUID()).email(UUID.randomUUID() + "@example.com").fullName(name)
                .passwordHash("h").privacy(Visibility.FRIENDS).createdAt(START).build();
        users.put(u.id(), u);
        return u;
    }

    private void friends(User a, User b) {
        Friendship f = Friendship.request(a.id(), b.id(), START);
        f.accept(b.id(), START);
        friendships.put(f.id(), f);
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

    private SubjectDirectoryPort subjectPort() {
        return new SubjectDirectoryPort() {
            public Optional<SubjectRef> findOwned(UUID u, UUID s) {
                return ownSubjects.getOrDefault(u, Set.of()).contains(s)
                        ? Optional.of(new SubjectRef(s, "Asignatura", null, 3, 6, null)) : Optional.empty();
            }
            public List<SubjectRef> findActive(UUID u) { return List.of(); }
            public Map<UUID, String> namesOf(UUID u, Collection<UUID> ids) { return Map.of(); }
        };
    }

    private static final class EmptyStreaks implements FriendStreakRepositoryPort {
        public Optional<FriendStreak> findById(UUID id) { return Optional.empty(); }
        public Optional<FriendStreak> findBetween(UUID a, UUID b) { return Optional.empty(); }
        public List<FriendStreak> findByUser(UUID u) { return List.of(); }
        public FriendStreak save(FriendStreak s) { return s; }
        public void delete(UUID id) { }
    }

    private static final class EmptyChallenges implements FriendChallengeRepositoryPort {
        public Optional<FriendChallenge> findById(UUID id) { return Optional.empty(); }
        public Optional<FriendChallenge> findByIdForUpdate(UUID id) { return Optional.empty(); }
        public FriendChallenge save(FriendChallenge c) { return c; }
        public List<FriendChallenge> findVisibleTo(UUID u, Instant after) { return List.of(); }
    }

    private static final class EmptyWorkouts implements WorkoutTogetherRepositoryPort {
        public Optional<WorkoutTogether> findById(UUID id) { return Optional.empty(); }
        public Optional<WorkoutTogether> findByIdForUpdate(UUID id) { return Optional.empty(); }
        public WorkoutTogether save(WorkoutTogether w) { return w; }
        public List<WorkoutTogether> findVisibleTo(UUID u, LocalDate from) { return List.of(); }
        public Optional<WorkoutTogether> findBySession(UUID s) { return Optional.empty(); }
    }

    /** Reloj que avanza a mano. */
    private static final class MutableClock extends Clock {

        private Instant now;

        MutableClock(Instant now) {
            this.now = now;
        }

        void advance(Duration d) {
            now = now.plus(d);
        }

        @Override
        public ZoneId getZone() {
            return UTC;
        }

        @Override
        public Clock withZone(ZoneId zone) {
            return this;
        }

        @Override
        public Instant instant() {
            return now;
        }
    }
}
