package com.synaptixfit.application.service.together;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.application.port.input.notification.CreateNotificationUseCase;
import com.synaptixfit.application.port.input.together.CreateFriendChallengeUseCase;
import com.synaptixfit.application.port.input.together.FriendChallengeView;
import com.synaptixfit.application.port.input.together.FriendStreakView;
import com.synaptixfit.domain.exception.together.FriendStreakAlreadyExistsException;
import com.synaptixfit.domain.exception.together.FriendStreakLimitReachedException;
import com.synaptixfit.domain.exception.together.FriendStreakNudgeUnavailableException;
import com.synaptixfit.domain.exception.together.TogetherInvalidStateException;
import com.synaptixfit.domain.exception.together.TogetherNotFriendsException;
import com.synaptixfit.domain.model.badge.StreakPause;
import com.synaptixfit.domain.model.challenge.ActivityFact;
import com.synaptixfit.domain.model.challenge.ActivityKind;
import com.synaptixfit.domain.model.challenge.ChallengeRule;
import com.synaptixfit.domain.model.challenge.ChallengeTemplate;
import com.synaptixfit.domain.model.challenge.ChallengeType;
import com.synaptixfit.domain.model.challenge.Difficulty;
import com.synaptixfit.domain.model.challenge.RoutineDayTarget;
import com.synaptixfit.domain.model.challenge.RuleMetric;
import com.synaptixfit.domain.model.challenge.RuleUnit;
import com.synaptixfit.domain.model.challenge.StudyBlockProgress;
import com.synaptixfit.domain.model.notification.NotificationMessage;
import com.synaptixfit.domain.model.notification.ReminderOptions;
import com.synaptixfit.domain.model.shared.Visibility;
import com.synaptixfit.domain.model.social.Friendship;
import com.synaptixfit.domain.model.together.FriendChallenge;
import com.synaptixfit.domain.model.together.FriendChallengeMode;
import com.synaptixfit.domain.model.together.FriendStreak;
import com.synaptixfit.domain.model.together.MemberStatus;
import com.synaptixfit.domain.model.together.Reaction;
import com.synaptixfit.domain.model.together.ReactionRecord;
import com.synaptixfit.domain.model.together.WorkoutTogether;
import com.synaptixfit.domain.model.user.User;
import com.synaptixfit.domain.port.output.badge.StreakPauseRepositoryPort;
import com.synaptixfit.domain.port.output.challenge.ChallengeReferencePort;
import com.synaptixfit.domain.port.output.challenge.ChallengeTemplateRepositoryPort;
import com.synaptixfit.domain.port.output.notification.ReminderOptionsRepositoryPort;
import com.synaptixfit.domain.port.output.social.FriendshipRepositoryPort;
import com.synaptixfit.domain.port.output.together.FriendChallengeReactionPort;
import com.synaptixfit.domain.port.output.together.FriendChallengeRepositoryPort;
import com.synaptixfit.domain.port.output.together.FriendStreakRepositoryPort;
import com.synaptixfit.domain.port.output.together.WorkoutTogetherRepositoryPort;
import com.synaptixfit.domain.port.output.user.UserRepositoryPort;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
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

/** Servicios de «Con amigos» (ADR 0044) con dobles en memoria: amigos mutuos, rachas, retos y salir al bloquear. */
class TogetherServicesTest {

    private static final ZoneId UTC = ZoneOffset.UTC;
    private static final Clock CLOCK = Clock.fixed(Instant.parse("2026-11-18T18:00:00Z"), UTC);

    private final Map<UUID, User> users = new HashMap<>();
    private final Map<UUID, Friendship> friendships = new HashMap<>();
    private final Map<UUID, FriendStreak> streaks = new HashMap<>();
    private final Map<UUID, FriendChallenge> challenges = new HashMap<>();
    private final Map<UUID, WorkoutTogether> workouts = new HashMap<>();
    private final List<ReactionRecord> reactions = new ArrayList<>();
    private final Map<UUID, List<ActivityFact>> facts = new HashMap<>();
    private final Map<UUID, List<StreakPause>> pauses = new HashMap<>();
    private final Map<UUID, ReminderOptions> options = new HashMap<>();
    private final List<CreateNotificationUseCase.Command> sent = new ArrayList<>();
    /** Lecturas bloqueadas ({@code findByIdForUpdate}) de retos y entrenos, por id. */
    private final List<UUID> locked = new ArrayList<>();

    private FriendStreakService streakService;
    private FriendChallengeService challengeService;
    private TogetherCleanupService cleanup;
    private ChallengeTemplate reviews;
    private ChallengeTemplate checkIns;
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
        reviews = new ChallengeTemplate(UUID.randomUUID(), "repasa", ChallengeType.ACADEMIC, Difficulty.MEDIUM, 14,
                new ChallengeRule(RuleMetric.REVIEWS, RuleUnit.DAY, 1, 12, false), "Repasa cada día", "Meta");
        checkIns = new ChallengeTemplate(UUID.randomUUID(), "registro", ChallengeType.FITNESS, Difficulty.MEDIUM, 21,
                new ChallengeRule(RuleMetric.CHECK_INS, RuleUnit.DAY, 1, 18, false), "Registro diario", "Meta");
        TogetherPeople people = new TogetherPeople(friendshipPort(), userPort());
        TogetherNotifier notifier = new TogetherNotifier(c -> {
            sent.add(c);
            return Optional.empty();
        }, userPort(), change -> { });
        streakService = new FriendStreakService(streakPort(), activityPort(), pausePort(), optionsPort(), people,
                notifier, CLOCK, UTC);
        challengeService = new FriendChallengeService(challengePort(), reactionPort(), templatePort(), activityPort(),
                userPort(), people, notifier, CLOCK, UTC);
        StudyRoomService studyRooms = new StudyRoomService(new InMemoryStudyRooms(), null, null, people, notifier,
                CLOCK, new com.synaptixfit.domain.model.planner.PlannerZone(UTC));
        cleanup = new TogetherCleanupService(streakPort(), challengePort(), workoutPort(), studyRooms, CLOCK, UTC);
    }

    @Test
    void onlyMutualFriendsAndUpToFiveStreaksEach() {
        User stranger = user("Desconocida");
        assertThatThrownBy(() -> streakService.propose(me.id(), stranger.id()))
                .isInstanceOf(TogetherNotFriendsException.class);
        FriendStreakView pending = streakService.propose(me.id(), ana.id());
        assertThat(pending.status()).isEqualTo(FriendStreak.Status.PENDING);
        assertThat(sent).singleElement().satisfies(c -> {
            assertThat(c.userId()).isEqualTo(ana.id());
            assertThat(c.message().code()).isEqualTo(NotificationMessage.Code.FRIEND_STREAK_INVITED);
        });
        assertThatThrownBy(() -> streakService.propose(ana.id(), me.id()))
                .isInstanceOf(FriendStreakAlreadyExistsException.class);
        for (int i = 0; i < 4; i++) {
            User other = user("Amigo " + i);
            friends(me, other);
            streakService.propose(me.id(), other.id());
        }
        User sixth = user("Sexto");
        friends(me, sixth);
        assertThatThrownBy(() -> streakService.propose(me.id(), sixth.id()))
                .isInstanceOf(FriendStreakLimitReachedException.class);
    }

    @Test
    void theNudgeRespectsTheFriendsStreakRemindersAndOnlyOnceADay() {
        FriendStreakView pending = streakService.propose(me.id(), ana.id());
        FriendStreakView active = streakService.accept(ana.id(), pending.id());
        assertThat(active.status()).isEqualTo(FriendStreak.Status.ACTIVE);
        sent.clear();
        assertThatThrownBy(() -> streakService.nudge(me.id(), pending.id()))
                .isInstanceOf(FriendStreakNudgeUnavailableException.class);
        did(me, ActivityKind.FOCUS);
        FriendStreakView afterNudge = streakService.nudge(me.id(), pending.id());
        assertThat(afterNudge.meDone()).isTrue();
        assertThat(afterNudge.friendDone()).isFalse();
        assertThat(afterNudge.canNudge()).isFalse();
        assertThat(sent).singleElement()
                .satisfies(c -> assertThat(c.message().code()).isEqualTo(NotificationMessage.Code.FRIEND_STREAK_NUDGE));

        assertThatThrownBy(() -> streakService.nudge(me.id(), pending.id()))
                .isInstanceOf(FriendStreakNudgeUnavailableException.class);
        did(ana, ActivityKind.WORKOUT);
        FriendStreakView both = streakService.overview(me.id(), new TogetherPeople(friendshipPort(), userPort())
                .lookup()).getFirst();
        assertThat(both.days()).isEqualTo(1);
        assertThat(both.friendDone()).isTrue();
    }

    @Test
    void aSilencedFriendIsNotNotified() {
        options.put(ana.id(), new ReminderOptions(false, true, true));
        FriendStreakView pending = streakService.propose(me.id(), ana.id());
        streakService.accept(ana.id(), pending.id());
        sent.clear();
        did(me, ActivityKind.REVIEW);
        streakService.nudge(me.id(), pending.id());
        assertThat(sent).isEmpty();
    }

    @Test
    void cooperativeChallengeShowsTheGroupTotalAndReactionCountsOnlyToTheirAuthor() {
        FriendChallengeView created = challengeService.create(new CreateFriendChallengeUseCase.Command(me.id(),
                reviews.id(), 7, null, Set.of(ana.id())), "es");
        assertThat(created.mode()).isEqualTo(FriendChallengeMode.COOPERATIVE);
        assertThat(created.groupTarget()).isEqualTo(6);
        challengeService.join(ana.id(), created.id(), "es");
        did(me, ActivityKind.REVIEW);
        did(ana, ActivityKind.REVIEW);
        LocalDate today = LocalDate.ofInstant(CLOCK.instant(), UTC);
        challengeService.react(ana.id(), created.id(), me.id(), today, Reaction.CLAP);
        assertThatThrownBy(() -> challengeService.react(me.id(), created.id(), me.id(), today, Reaction.FIRE))
                .isInstanceOf(TogetherInvalidStateException.class);

        FriendChallengeView mine = challengeService.get(me.id(), created.id(), "es");
        assertThat(mine.groupTotal()).isEqualTo(2);
        assertThat(mine.groupTarget()).isEqualTo(12);
        assertThat(mine.members()).allSatisfy(m -> assertThat(m.points()).isNull());
        assertThat(mine.board()).filteredOn(FriendChallengeView.BoardEntry::mine).singleElement()
                .satisfies(e -> assertThat(e.counts()).containsEntry(Reaction.CLAP, 1));
        FriendChallengeView hers = challengeService.get(ana.id(), created.id(), "es");
        assertThat(hers.board()).filteredOn(e -> !e.mine()).singleElement().satisfies(e -> {
            assertThat(e.counts()).isEmpty();
            assertThat(e.myReaction()).isEqualTo(Reaction.CLAP);
        });
    }

    @Test
    void wellbeingTemplatesNeverGoToFriendsAndOnlyFriendsAreInvited() {
        assertThat(challengeService.friendTemplates(me.id(), "es")).extracting(ChallengeTemplate::code)
                .containsExactly("repasa");
        User stranger = user("Desconocida");
        assertThatThrownBy(() -> challengeService.create(new CreateFriendChallengeUseCase.Command(me.id(),
                reviews.id(), 7, FriendChallengeMode.COMPETITION, Set.of(stranger.id())), "es"))
                .isInstanceOf(TogetherNotFriendsException.class);
        assertThat(challenges).isEmpty();
    }

    @Test
    void blockingLeavesWhatWasSharedBetweenTheTwo() {
        FriendStreakView streak = streakService.propose(me.id(), ana.id());
        FriendChallengeView mineChallenge = challengeService.create(new CreateFriendChallengeUseCase.Command(me.id(),
                reviews.id(), 7, null, Set.of(ana.id(), luis.id())), "es");
        challengeService.join(ana.id(), mineChallenge.id(), "es");
        challengeService.join(luis.id(), mineChallenge.id(), "es");

        cleanup.leaveShared(me.id(), ana.id(), true);

        assertThat(streaks).doesNotContainKey(streak.id());
        FriendChallenge c = challenges.get(mineChallenge.id());
        assertThat(c.members().find(ana.id()).orElseThrow().status()).isEqualTo(MemberStatus.LEFT);
        assertThat(c.members().find(luis.id()).orElseThrow().status()).isEqualTo(MemberStatus.JOINED);
        cleanup.leaveShared(me.id(), ana.id(), true);
        assertThat(c.members().find(ana.id()).orElseThrow().status()).isEqualTo(MemberStatus.LEFT);
    }

    // ------------------------------------------------------------------ lectura bloqueada (ADR 0045)

    private FriendChallengeView challengeWithAna() {
        return challengeService.create(new CreateFriendChallengeUseCase.Command(me.id(), reviews.id(), 7, null,
                Set.of(ana.id())), "es");
    }

    @Test
    void joiningAChallengeReadsItLocked() {
        FriendChallengeView c = challengeWithAna();
        locked.clear();
        challengeService.join(ana.id(), c.id(), "es");
        assertThat(locked).containsExactly(c.id());
    }

    @Test
    void decliningAChallengeReadsItLocked() {
        FriendChallengeView c = challengeWithAna();
        locked.clear();
        challengeService.decline(ana.id(), c.id());
        assertThat(locked).containsExactly(c.id());
    }

    @Test
    void leavingAChallengeReadsItLocked() {
        FriendChallengeView c = challengeWithAna();
        challengeService.join(ana.id(), c.id(), "es");
        locked.clear();
        challengeService.leave(ana.id(), c.id());
        assertThat(locked).containsExactly(c.id());
    }

    @Test
    void reactingAndRemovingAReactionReadTheChallengeLocked() {
        FriendChallengeView c = challengeWithAna();
        challengeService.join(ana.id(), c.id(), "es");
        did(me, ActivityKind.REVIEW);
        LocalDate today = LocalDate.ofInstant(CLOCK.instant(), UTC);
        locked.clear();
        challengeService.react(ana.id(), c.id(), me.id(), today, Reaction.FIRE);
        assertThat(locked).containsExactly(c.id());
        locked.clear();
        challengeService.removeReaction(ana.id(), c.id(), me.id(), today);
        assertThat(locked).containsExactly(c.id());
    }

    @Test
    void endingAFriendshipReadsWhatIsSharedLocked() {
        FriendChallengeView c = challengeWithAna();
        challengeService.join(ana.id(), c.id(), "es");
        WorkoutTogether w = WorkoutTogether.create(me.id(), UUID.randomUUID(), UUID.randomUUID(), Set.of(ana.id()),
                LocalDate.ofInstant(CLOCK.instant(), UTC), CLOCK.instant());
        workouts.put(w.id(), w);
        locked.clear();
        cleanup.leaveShared(me.id(), ana.id(), false);
        assertThat(locked).contains(c.id(), w.id());
        assertThat(w.members().find(ana.id()).orElseThrow().status()).isEqualTo(MemberStatus.DECLINED);
    }

    // ------------------------------------------------------------------ dobles

    private User user(String name) {
        User u = User.builder().id(UUID.randomUUID()).email(UUID.randomUUID() + "@example.com").fullName(name)
                .passwordHash("h").privacy(Visibility.FRIENDS).createdAt(CLOCK.instant()).build();
        users.put(u.id(), u);
        return u;
    }

    private void friends(User a, User b) {
        Friendship f = Friendship.request(a.id(), b.id(), CLOCK.instant());
        f.accept(b.id(), CLOCK.instant());
        friendships.put(f.id(), f);
    }

    private void did(User u, ActivityKind kind) {
        facts.computeIfAbsent(u.id(), k -> new ArrayList<>()).add(ActivityFact.at(kind, CLOCK.instant(), 25));
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

    private FriendStreakRepositoryPort streakPort() {
        return new FriendStreakRepositoryPort() {
            public Optional<FriendStreak> findById(UUID id) { return Optional.ofNullable(streaks.get(id)); }
            public Optional<FriendStreak> findBetween(UUID a, UUID b) {
                return streaks.values().stream().filter(s -> s.involves(a) && s.involves(b)).findFirst();
            }
            public List<FriendStreak> findByUser(UUID u) {
                return streaks.values().stream().filter(s -> s.involves(u)).toList();
            }
            public FriendStreak save(FriendStreak s) { streaks.put(s.id(), s); return s; }
            public void delete(UUID id) { streaks.remove(id); }
        };
    }

    private FriendChallengeRepositoryPort challengePort() {
        return new FriendChallengeRepositoryPort() {
            public Optional<FriendChallenge> findById(UUID id) { return Optional.ofNullable(challenges.get(id)); }
            public Optional<FriendChallenge> findByIdForUpdate(UUID id) {
                locked.add(id);
                return findById(id);
            }
            public FriendChallenge save(FriendChallenge c) { challenges.put(c.id(), c); return c; }
            public List<FriendChallenge> findVisibleTo(UUID u, Instant after) {
                return challenges.values().stream().filter(c -> c.canView(u) && c.endAt().isAfter(after)).toList();
            }
        };
    }

    private FriendChallengeReactionPort reactionPort() {
        return new FriendChallengeReactionPort() {
            public void put(ReactionRecord r) {
                remove(r.challengeId(), r.recipientId(), r.day(), r.authorId());
                reactions.add(r);
            }
            public void remove(UUID c, UUID rec, LocalDate d, UUID a) {
                reactions.removeIf(r -> r.challengeId().equals(c) && r.recipientId().equals(rec) && r.day().equals(d)
                        && r.authorId().equals(a));
            }
            public List<ReactionRecord> findByChallenge(UUID c) {
                return reactions.stream().filter(r -> r.challengeId().equals(c)).toList();
            }
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
            public Optional<WorkoutTogether> findBySession(UUID s) { return Optional.empty(); }
        };
    }

    private ChallengeTemplateRepositoryPort templatePort() {
        return new ChallengeTemplateRepositoryPort() {
            public List<ChallengeTemplate> findAll(String language) { return List.of(reviews, checkIns); }
            public Optional<ChallengeTemplate> findById(UUID id, String language) {
                return findAll(language).stream().filter(t -> t.id().equals(id)).findFirst();
            }
        };
    }

    private StreakPauseRepositoryPort pausePort() {
        return new StreakPauseRepositoryPort() {
            public List<StreakPause> findByUser(UUID u) { return pauses.getOrDefault(u, List.of()); }
            public StreakPause save(StreakPause p) { return p; }
            public void delete(UUID id) { }
        };
    }

    private ReminderOptionsRepositoryPort optionsPort() {
        return new ReminderOptionsRepositoryPort() {
            public Optional<ReminderOptions> find(UUID u) { return Optional.ofNullable(options.get(u)); }
            public void save(UUID u, ReminderOptions o, Instant now) { options.put(u, o); }
        };
    }

    private ChallengeReferencePort activityPort() {
        return new ChallengeReferencePort() {
            public boolean subjectBelongsTo(UUID u, UUID s) { return false; }
            public boolean deadlineBelongsTo(UUID u, UUID d) { return false; }
            public boolean routineDayBelongsTo(UUID u, UUID d) { return false; }
            public List<RoutineDayTarget> routineDayTargets(UUID u) { return List.of(); }
            public boolean noteBelongsTo(UUID u, UUID n) { return false; }
            public boolean fileBelongsTo(UUID u, UUID f) { return false; }
            public StudyBlockProgress studyBlockProgress(UUID u, UUID m) { return null; }
            public int completedTrainingSessions(UUID u, Instant from, Instant to) { return 0; }
            public List<ActivityFact> activity(UUID u, Set<ActivityKind> kinds, Instant from, Instant to) {
                return facts.getOrDefault(u, List.of()).stream().filter(f -> kinds.contains(f.kind())).toList();
            }
        };
    }
}
