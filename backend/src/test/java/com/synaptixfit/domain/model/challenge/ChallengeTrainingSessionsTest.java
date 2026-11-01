package com.synaptixfit.domain.model.challenge;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.domain.exception.FieldValidationException;
import com.synaptixfit.domain.model.shared.Visibility;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** Retos de fitness por sesiones de entrenamiento (ADR 0009): recuento idempotente y reversible. */
class ChallengeTrainingSessionsTest {

    private static final Instant NOW = Instant.parse("2026-10-01T10:00:00Z");
    private static final LocalDate TODAY = LocalDate.parse("2026-10-01");

    private static Challenge fitness(Integer target) {
        return Challenge.create(UUID.randomUUID(), UUID.randomUUID(),
                new ChallengeDetails("Entrenar 3 veces", ChallengeType.FITNESS, null, Visibility.PRIVATE,
                        Difficulty.MEDIUM, NOW, NOW.plusSeconds(86_400 * 7), null, null, target), List.of(), NOW);
    }

    @Test
    void reachingTheTargetCompletesWithXpAndRecountingIsIdempotent() {
        Challenge c = fitness(3);

        ChallengeChanges two = c.applyTrainingSessions(2, TODAY);
        assertThat(two.xpDelta()).isZero();
        assertThat(c.progress()).isEqualTo(66.67);
        assertThat(c.currentStreak()).isEqualTo(1);

        ChallengeChanges three = c.applyTrainingSessions(3, TODAY);
        assertThat(three.challengeCompleted()).isTrue();
        assertThat(three.xpDelta()).isEqualTo(Difficulty.MEDIUM.xp());
        assertThat(c.progress()).isEqualTo(100.0);

        ChallengeChanges again = c.applyTrainingSessions(3, TODAY);
        assertThat(again.xpDelta()).isZero();
        assertThat(again.challengeCompleted()).isFalse();
    }

    @Test
    void droppingBelowTheTargetUncompletesAndRevokesTheExactXp() {
        Challenge c = fitness(2);
        c.applyTrainingSessions(2, TODAY);

        ChallengeChanges unmarked = c.applyTrainingSessions(1, TODAY);

        assertThat(unmarked.challengeUncompleted()).isTrue();
        assertThat(unmarked.xpDelta()).isEqualTo(-Difficulty.MEDIUM.xp());
        assertThat(c.completed()).isFalse();
        assertThat(c.sessionsCompleted()).isEqualTo(1);
    }

    @Test
    void aManualCompletionBelowTheTargetIsNotUndoneByTheRecount() {
        Challenge c = fitness(5);
        c.applyTrainingSessions(1, TODAY);
        c.complete(TODAY);

        ChallengeChanges recount = c.applyTrainingSessions(0, TODAY);

        assertThat(recount.xpDelta()).isZero();
        assertThat(c.completed()).isTrue();
    }

    @Test
    void aManualCompletionBelowTheTargetGivesXpOnlyWhenTheSessionsReachIt() {
        Challenge c = fitness(3);
        c.applyTrainingSessions(1, TODAY);

        // Antes un toque daba la XP del reto sin haber entrenado.
        assertThat(c.complete(TODAY).xpDelta()).isZero();
        assertThat(c.completed()).isTrue();

        assertThat(c.applyTrainingSessions(3, TODAY).xpDelta()).isEqualTo(Difficulty.MEDIUM.xp());
        assertThat(c.applyTrainingSessions(3, TODAY).xpDelta()).isZero();
    }

    @Test
    void onlyFitnessChallengesWithoutTasksTrackSessions() {
        assertThat(fitness(null).tracksTrainingSessions()).isFalse();
        assertThat(fitness(null).applyTrainingSessions(10, TODAY).xpDelta()).isZero();

        Challenge withTasks = fitness(2);
        withTasks.replaceMilestones(List.of(new MilestoneDraft(null, "Tarea uno", Difficulty.LOW, null, null,
                null, null, List.of(), null, null)));
        assertThat(withTasks.tracksTrainingSessions()).isFalse();

        assertThatThrownBy(() -> Challenge.create(UUID.randomUUID(), UUID.randomUUID(),
                new ChallengeDetails("Leer 3 capítulos", ChallengeType.ACADEMIC, null, Visibility.PRIVATE,
                        Difficulty.MEDIUM, NOW, NOW.plusSeconds(86_400), null, null, 3), List.of(), NOW))
                .isInstanceOf(FieldValidationException.class);
        assertThatThrownBy(() -> fitness(0)).isInstanceOf(FieldValidationException.class);
    }

    @Test
    void cloningKeepsTheTargetButNotTheCount() {
        Challenge c = fitness(4);
        c.applyTrainingSessions(3, TODAY);

        Challenge copy = c.cloneFor(UUID.randomUUID(), UUID.randomUUID(), "Ana", NOW);

        assertThat(copy.sessionTarget()).isEqualTo(4);
        assertThat(copy.sessionsCompleted()).isZero();
    }
}
