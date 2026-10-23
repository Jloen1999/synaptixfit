package com.synaptixfit.application.service.challenge;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.application.port.input.challenge.CreateChallengeUseCase;
import com.synaptixfit.domain.exception.challenge.ChallengeTypeOutsideFocusException;
import com.synaptixfit.domain.model.challenge.Challenge;
import com.synaptixfit.domain.model.challenge.ChallengeDetails;
import com.synaptixfit.domain.model.challenge.ChallengeQuery;
import com.synaptixfit.domain.model.challenge.ChallengeType;
import com.synaptixfit.domain.model.challenge.Difficulty;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.Visibility;
import com.synaptixfit.domain.model.user.UsageFocus;
import com.synaptixfit.domain.model.user.User;
import com.synaptixfit.domain.port.output.user.UserRepositoryPort;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/** Retos y enfoque de uso: solo se crean y se listan los del ámbito que la persona usa. */
class ChallengeFocusTest {

    private static final Instant NOW = ChallengeFixtures.CLOCK.instant();
    private final UUID athleteId = UUID.randomUUID();
    private ChallengeService service;

    @BeforeEach
    void setUp() {
        ChallengeFixtures f = new ChallengeFixtures();
        User athlete = User.builder().id(athleteId).email("andres@example.com").fullName("Andrés")
                .passwordHash("h").usageFocus(UsageFocus.FITNESS).build();
        UserRepositoryPort users = new UserRepositoryPort() {
            public Optional<User> findById(UUID id) { return id.equals(athleteId) ? Optional.of(athlete) : Optional.empty(); }
            public Optional<User> findByEmail(String e) { return Optional.empty(); }
            public Optional<User> findByGoogleSubject(String s) { return Optional.empty(); }
            public boolean existsByEmail(String e) { return false; }
            public User save(User u) { return u; }
        };
        service = new ChallengeService(f.repository, f.audience, users, new ChallengeReferenceValidator(f.references),
                f.references, f.effects(), ChallengeFixtures.CLOCK, java.time.ZoneOffset.UTC);
    }

    private CreateChallengeUseCase.Command create(ChallengeType type) {
        return new CreateChallengeUseCase.Command(athleteId, new ChallengeDetails("Correr 5 km", type, null,
                Visibility.PRIVATE, Difficulty.MEDIUM, NOW, NOW.plusSeconds(86_400), null, null), List.of());
    }

    @Test
    void anAthleteCannotCreateAnAcademicChallenge() {
        assertThatThrownBy(() -> service.createChallenge(create(ChallengeType.ACADEMIC)))
                .isInstanceOf(ChallengeTypeOutsideFocusException.class)
                .hasFieldOrPropertyWithValue("code", "CHALLENGE_TYPE_OUTSIDE_FOCUS");
        assertThat(service.createChallenge(create(ChallengeType.FITNESS)).type()).isEqualTo(ChallengeType.FITNESS);
    }

    @Test
    void askingForTheOtherAreaReturnsAnEmptyPage() {
        Challenge mine = service.createChallenge(create(ChallengeType.FITNESS));

        assertThat(service.listMyChallenges(athleteId, new ChallengeQuery(null, ChallengeType.ACADEMIC, null, null),
                new PageRequest(0, 10)).items()).isEmpty();
        assertThat(service.listMyChallenges(athleteId, new ChallengeQuery(null, null, null, null),
                new PageRequest(0, 10)).items()).extracting(Challenge::id).containsExactly(mine.id());
    }
}
