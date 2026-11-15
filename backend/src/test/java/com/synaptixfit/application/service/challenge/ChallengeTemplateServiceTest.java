package com.synaptixfit.application.service.challenge;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.domain.event.challenge.ChallengeCompleted;
import com.synaptixfit.domain.exception.challenge.ChallengeTemplateAlreadyActiveException;
import com.synaptixfit.domain.exception.challenge.ChallengeTemplateNotFoundException;
import com.synaptixfit.domain.model.challenge.ActivityFact;
import com.synaptixfit.domain.model.challenge.ActivityKind;
import com.synaptixfit.domain.model.challenge.Challenge;
import com.synaptixfit.domain.model.challenge.ChallengeRule;
import com.synaptixfit.domain.model.challenge.ChallengeTemplate;
import com.synaptixfit.domain.model.challenge.ChallengeType;
import com.synaptixfit.domain.model.challenge.Difficulty;
import com.synaptixfit.domain.model.challenge.RuleMetric;
import com.synaptixfit.domain.model.challenge.RuleUnit;
import com.synaptixfit.domain.model.shared.Visibility;
import com.synaptixfit.domain.model.user.UsageFocus;
import com.synaptixfit.domain.model.user.User;
import com.synaptixfit.domain.port.output.challenge.ChallengeTemplateRepositoryPort;
import com.synaptixfit.domain.port.output.user.UserRepositoryPort;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/**
 * Plantillas de reto (ADR 0043): se listan según el modo de uso, «Empezar» crea un reto privado que se cuenta solo, no
 * se repite uno en marcha y los eventos lo recuentan (con su XP).
 */
class ChallengeTemplateServiceTest {

    private static final Instant NOW = ChallengeFixtures.CLOCK.instant();

    private final ChallengeFixtures f = new ChallengeFixtures();
    private final UUID userId = UUID.randomUUID();
    private UsageFocus focus = UsageFocus.BOTH;

    private final ChallengeTemplate reviews = new ChallengeTemplate(UUID.randomUUID(), "repasa_cada_dia",
            ChallengeType.ACADEMIC, Difficulty.MEDIUM, 14,
            new ChallengeRule(RuleMetric.REVIEWS, RuleUnit.DAY, 1, 2, false), "Repasa cada día", "Un repaso al día");
    private final ChallengeTemplate checkIns = new ChallengeTemplate(UUID.randomUUID(), "registro_diario",
            ChallengeType.FITNESS, Difficulty.MEDIUM, 21,
            new ChallengeRule(RuleMetric.CHECK_INS, RuleUnit.DAY, 1, 1, false), "¿Qué tal estás? 3 semanas", "Meta");

    private final ChallengeTemplateRepositoryPort templates = new ChallengeTemplateRepositoryPort() {
        public List<ChallengeTemplate> findAll(String language) { return List.of(reviews, checkIns); }
        public Optional<ChallengeTemplate> findById(UUID id, String language) {
            return findAll(language).stream().filter(t -> t.id().equals(id)).findFirst();
        }
    };

    private final UserRepositoryPort users = new UserRepositoryPort() {
        public Optional<User> findById(UUID id) {
            return Optional.of(User.builder().id(id).email("ana@example.com").fullName("Ana").passwordHash("h")
                    .usageFocus(focus).build());
        }
        public Optional<User> findByEmail(String e) { return Optional.empty(); }
        public Optional<User> findByGoogleSubject(String s) { return Optional.empty(); }
        public boolean existsByEmail(String e) { return false; }
        public User save(User u) { return u; }
    };

    private final ChallengeTemplateService service = new ChallengeTemplateService(templates, f.repository, users,
            f.references, f.effects(), ChallengeFixtures.CLOCK, ZoneOffset.UTC);
    private final ChallengeProgressService progress = new ChallengeProgressService(f.repository, f.references,
            new ChallengeReferenceValidator(f.references), f.effects(), ChallengeFixtures.CLOCK, ZoneOffset.UTC);

    @Test
    void listsOnlyTemplatesForTheUsageFocusAndMarksTheRunningOnes() {
        focus = UsageFocus.ACADEMIC;
        assertThat(service.listTemplates(userId, "es").templates()).extracting(ChallengeTemplate::code)
                .containsExactly("repasa_cada_dia");

        service.startTemplate(userId, reviews.id(), "es");

        assertThat(service.listTemplates(userId, "es").running()).containsExactly("repasa_cada_dia");
        assertThatThrownBy(() -> service.startTemplate(userId, checkIns.id(), "es"))
                .isInstanceOf(ChallengeTemplateNotFoundException.class);
    }

    @Test
    void startCreatesAPrivateChallengeThatCountsItselfAndCannotRunTwice() {
        Challenge c = service.startTemplate(userId, reviews.id(), "es");

        assertThat(c.title()).isEqualTo("Repasa cada día");
        assertThat(c.visibility()).isEqualTo(Visibility.PRIVATE);
        assertThat(c.tracksRule()).isTrue();
        assertThat(c.templateCode()).isEqualTo("repasa_cada_dia");
        assertThat(c.startAt()).isEqualTo(NOW);
        assertThatThrownBy(() -> service.startTemplate(userId, reviews.id(), "es"))
                .isInstanceOf(ChallengeTemplateAlreadyActiveException.class)
                .hasFieldOrPropertyWithValue("code", "CHALLENGE_TEMPLATE_ALREADY_ACTIVE");
    }

    @Test
    void eventsRecountTheRuleAndCompleteTheChallengeWithXp() {
        Challenge c = service.startTemplate(userId, reviews.id(), "es");
        f.activity.add(ActivityFact.at(ActivityKind.REVIEW, NOW.plusSeconds(60), 1));
        progress.syncRuleChallenges(userId);
        assertThat(f.store.get(c.id()).ruleProgress()).isEqualTo(1);
        assertThat(f.netXp()).isZero();

        f.activity.add(ActivityFact.at(ActivityKind.REVIEW, NOW.plusSeconds(86_400), 1));
        progress.syncRuleChallenges(userId);

        assertThat(f.store.get(c.id()).completed()).isTrue();
        assertThat(f.netXp()).isEqualTo(Difficulty.MEDIUM.xp());
        assertThat(f.events).filteredOn(ChallengeCompleted.class::isInstance).hasSize(1);
    }

    @Test
    void cloningARunningTemplateChallengeIsLikeStartingItTwice() {
        Challenge c = service.startTemplate(userId, reviews.id(), "es");
        ChallengeService challenges = new ChallengeService(f.repository, f.audience, users,
                new ChallengeReferenceValidator(f.references), f.references, f.effects(), ChallengeFixtures.CLOCK,
                ZoneOffset.UTC);

        assertThatThrownBy(() -> challenges.cloneChallenge(userId, c.id()))
                .isInstanceOf(ChallengeTemplateAlreadyActiveException.class);

        focus = UsageFocus.FITNESS;
        assertThatThrownBy(() -> challenges.cloneChallenge(userId, c.id()))
                .isInstanceOf(com.synaptixfit.domain.exception.challenge.ChallengeTypeOutsideFocusException.class);
    }

    @Test
    void aTemplateChallengeCannotStartBeforeItWasCreated() {
        Challenge c = service.startTemplate(userId, reviews.id(), "es");

        c.updateDetails(new com.synaptixfit.domain.model.challenge.ChallengeDetails(c.title(), c.type(), c.goal(),
                c.visibility(), c.difficulty(), NOW.minusSeconds(86_400 * 7), c.endAt(), null, null));

        assertThat(c.startAt()).isEqualTo(NOW);
    }

    @Test
    void aCompletedWellbeingChallengeIsNotPostedToTheWall() {
        f.activity.add(new ActivityFact(ActivityKind.CHECK_IN, null, NOW.atZone(ZoneOffset.UTC).toLocalDate(), 1));

        Challenge c = service.startTemplate(userId, checkIns.id(), "es");

        assertThat(c.completed()).isTrue();
        assertThat(f.events).filteredOn(ChallengeCompleted.class::isInstance)
                .extracting(e -> ((ChallengeCompleted) e).shareable()).containsExactly(false);
    }
}
