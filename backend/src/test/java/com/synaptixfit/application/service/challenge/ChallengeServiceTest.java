package com.synaptixfit.application.service.challenge;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.application.port.input.challenge.ChallengeView;
import com.synaptixfit.application.port.input.challenge.CreateChallengeUseCase;
import com.synaptixfit.application.port.input.challenge.UpdateChallengeUseCase;
import com.synaptixfit.domain.exception.challenge.ChallengeLinkNotFoundException;
import com.synaptixfit.domain.exception.challenge.ChallengeNotFoundException;
import com.synaptixfit.domain.exception.challenge.ChallengeSubjectNotFoundException;
import com.synaptixfit.domain.model.challenge.Challenge;
import com.synaptixfit.domain.model.challenge.ChallengeDetails;
import com.synaptixfit.domain.model.challenge.ChallengeLink;
import com.synaptixfit.domain.model.challenge.ChallengeType;
import com.synaptixfit.domain.model.challenge.Difficulty;
import com.synaptixfit.domain.model.challenge.LinkType;
import com.synaptixfit.domain.model.challenge.MilestoneDraft;
import com.synaptixfit.domain.model.shared.Visibility;
import com.synaptixfit.domain.model.user.User;
import com.synaptixfit.domain.port.output.user.UserRepositoryPort;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/** Alta, consulta, edición, borrado y clonado de retos. */
class ChallengeServiceTest {

    private static final Instant NOW = ChallengeFixtures.CLOCK.instant();
    private final UUID userId = UUID.randomUUID();
    private final UUID authorId = UUID.randomUUID();
    private ChallengeFixtures f;
    private ChallengeService service;
    private ChallengeProgressService progress;

    @BeforeEach
    void setUp() {
        f = new ChallengeFixtures();
        User author = User.builder().id(authorId).email("ana@example.com").fullName("Ana Autora")
                .passwordHash("h").build();
        UserRepositoryPort users = new UserRepositoryPort() {
            public Optional<User> findById(UUID id) { return id.equals(authorId) ? Optional.of(author) : Optional.empty(); }
            public Optional<User> findByEmail(String e) { return Optional.empty(); }
            public Optional<User> findByGoogleSubject(String s) { return Optional.empty(); }
            public boolean existsByEmail(String e) { return false; }
            public User save(User u) { return u; }
        };
        ChallengeReferenceValidator validator = new ChallengeReferenceValidator(f.references);
        service = new ChallengeService(f.repository, f.audience, users, validator, f.references, f.effects(),
                ChallengeFixtures.CLOCK, java.time.ZoneOffset.UTC);
        progress = new ChallengeProgressService(f.repository, f.references, validator, f.effects(),
                ChallengeFixtures.CLOCK, java.time.ZoneOffset.UTC);
    }

    private ChallengeDetails details(UUID subject, ChallengeLink link) {
        return new ChallengeDetails("Correr 5 km", null, null, Visibility.PUBLIC, Difficulty.MEDIUM, NOW,
                NOW.plusSeconds(86_400), subject, link);
    }

    private static MilestoneDraft task(String title, List<Integer> deps) {
        return new MilestoneDraft(null, title, null, null, null, null, null, null, deps, null, null);
    }

    @Test
    void createValidatesSubjectAndLinkOwnership() {
        UUID subject = UUID.randomUUID();
        assertThatThrownBy(() -> service.createChallenge(
                new CreateChallengeUseCase.Command(userId, details(subject, null), List.of())))
                .isInstanceOf(ChallengeSubjectNotFoundException.class)
                .hasFieldOrPropertyWithValue("code", "CHALLENGE_SUBJECT_NOT_FOUND");

        UUID exam = UUID.randomUUID();
        assertThatThrownBy(() -> service.createChallenge(new CreateChallengeUseCase.Command(userId,
                details(null, new ChallengeLink(LinkType.EXAM, exam)), List.of())))
                .isInstanceOf(ChallengeLinkNotFoundException.class);

        f.ownedRefs.add(subject);
        f.ownedRefs.add(exam);
        Challenge created = service.createChallenge(new CreateChallengeUseCase.Command(userId,
                details(subject, new ChallengeLink(LinkType.EXAM, exam)), List.of(task("Tarea uno", List.of()))));
        assertThat(created.type()).isEqualTo(ChallengeType.ACADEMIC);
        assertThat(f.store).containsKey(created.id());
    }

    @Test
    void otherUsersChallengeIsVisibleOnlyWhenAudienceAllows() {
        Challenge foreign = f.repository.save(Challenge.create(UUID.randomUUID(), authorId, details(null, null),
                List.of(), NOW));

        assertThatThrownBy(() -> service.getChallenge(userId, foreign.id()))
                .isInstanceOf(ChallengeNotFoundException.class);

        f.audienceAllows = true;
        ChallengeView view = service.getChallenge(userId, foreign.id());
        assertThat(view.owned()).isFalse();
        assertThat(view.ownerName()).isEqualTo("Ana Autora");

        assertThatThrownBy(() -> service.deleteChallenge(userId, foreign.id()))
                .isInstanceOf(ChallengeNotFoundException.class);
    }

    @Test
    void deleteRevokesAllXpGrantedByTheChallengeAndItsTasks() {
        Challenge c = service.createChallenge(new CreateChallengeUseCase.Command(userId, details(null, null),
                List.of(task("Tarea uno", List.of()), task("Tarea dos", List.of()))));
        progress.completeChallenge(userId, c.id());
        assertThat(f.netXp()).isEqualTo(80);

        service.deleteChallenge(userId, c.id());
        assertThat(f.netXp()).isZero();
        assertThat(f.store).doesNotContainKey(c.id());
    }

    @Test
    void cloneCreatesPrivateCopyWithOriginAndRemappedDependencies() {
        Challenge foreign = f.repository.save(Challenge.create(UUID.randomUUID(), authorId, details(null, null),
                List.of(task("Base", List.of()), task("Final", List.of(0))), NOW));
        f.audienceAllows = true;

        Challenge copy = service.cloneChallenge(userId, foreign.id());

        assertThat(copy.ownerId()).isEqualTo(userId);
        assertThat(copy.visibility()).isEqualTo(Visibility.PRIVATE);
        assertThat(copy.originId()).isEqualTo(foreign.id());
        assertThat(copy.originOwnerId()).isEqualTo(authorId);
        assertThat(copy.originOwnerName()).isEqualTo("Ana Autora");
        assertThat(copy.milestones().get(1).dependencies()).containsExactly(copy.milestones().get(0).id());
    }

    @Test
    void updateChangesOnlyGivenFieldsAndClearsSubject() {
        UUID subject = UUID.randomUUID();
        f.ownedRefs.add(subject);
        Challenge c = service.createChallenge(new CreateChallengeUseCase.Command(userId, details(subject, null),
                List.of()));

        Challenge updated = service.updateChallenge(new UpdateChallengeUseCase.Command(userId, c.id(),
                "Correr 10 km", null, null, null, Difficulty.HIGH, null, null, null, true, null, null, false));

        assertThat(updated.title()).isEqualTo("Correr 10 km");
        assertThat(updated.difficulty()).isEqualTo(Difficulty.HIGH);
        assertThat(updated.subjectId()).isNull();
        assertThat(updated.visibility()).isEqualTo(Visibility.PUBLIC);
    }

    @Test
    void communityListsOnlyOthersChallengesWithOwnerName() {
        f.repository.save(Challenge.create(UUID.randomUUID(), authorId, details(null, null), List.of(), NOW));
        service.createChallenge(new CreateChallengeUseCase.Command(userId, details(null, null), List.of()));

        var page = service.listCommunityChallenges(userId, null, null, new com.synaptixfit.domain.model.shared.PageRequest(0, 20));
        assertThat(page.items()).hasSize(1);
        assertThat(page.items().getFirst().ownerName()).isEqualTo("Autor");
    }

    @Test
    void creatingOrLoweringTheSessionTargetCountsSessionsAlreadyDone() {
        f.trainingSessions.add(NOW.plusSeconds(60));
        f.trainingSessions.add(NOW.plusSeconds(120));
        Challenge created = service.createChallenge(new CreateChallengeUseCase.Command(userId,
                new ChallengeDetails("Entrenar tres veces", ChallengeType.FITNESS, null, Visibility.PRIVATE,
                        Difficulty.MEDIUM, NOW, NOW.plusSeconds(86_400), null, null, 3), List.of()));
        assertThat(created.sessionsCompleted()).isEqualTo(2);
        assertThat(created.completed()).isFalse();

        Challenge lowered = service.updateChallenge(new UpdateChallengeUseCase.Command(userId, created.id(), null,
                null, null, null, null, null, null, null, false, null, null, false, 2, false));
        assertThat(lowered.completed()).isTrue();
        assertThat(f.awarded).containsExactly(Difficulty.MEDIUM.xp());
    }
}
