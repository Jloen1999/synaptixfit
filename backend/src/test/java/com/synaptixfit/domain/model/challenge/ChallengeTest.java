package com.synaptixfit.domain.model.challenge;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.domain.exception.DomainException;
import com.synaptixfit.domain.exception.challenge.InvalidChallengeDatesException;
import com.synaptixfit.domain.exception.challenge.InvalidMilestoneDependencyException;
import com.synaptixfit.domain.exception.challenge.InvalidMilestoneWeightsException;
import com.synaptixfit.domain.exception.challenge.MilestoneLockedException;
import com.synaptixfit.domain.exception.challenge.ProgressMilestoneRequiredException;
import com.synaptixfit.domain.exception.challenge.TooManyMilestonesException;
import com.synaptixfit.domain.model.shared.Visibility;
import java.time.Instant;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.stream.IntStream;
import org.junit.jupiter.api.Test;

/** Reglas del agregado reto: XP con anti-farmeo, pesos, dependencias, progreso y racha. */
class ChallengeTest {

    private static final Instant NOW = Instant.parse("2026-10-01T10:00:00Z");
    private static final LocalDate TODAY = LocalDate.parse("2026-10-01");

    static ChallengeDetails details(Difficulty difficulty) {
        return new ChallengeDetails("Leer 3 capítulos", null, null, Visibility.PRIVATE, difficulty, NOW,
                NOW.plusSeconds(86_400 * 7), null, null);
    }

    static MilestoneDraft task(String title, Double weight, List<Integer> deps, UnlockCondition cond, Integer n) {
        return new MilestoneDraft(null, title, weight, Difficulty.MEDIUM, null, null, null, null, deps, cond, n);
    }

    static MilestoneDraft task(String title) {
        return task(title, null, List.of(), null, null);
    }

    private static Challenge withTasks(MilestoneDraft... drafts) {
        return Challenge.create(UUID.randomUUID(), UUID.randomUUID(), details(Difficulty.MEDIUM), List.of(drafts), NOW);
    }

    // ---------------------------------------------------------------- XP y anti-farmeo

    @Test
    void completingWithoutTasksAwardsDifficultyXpOnceAndUncompletingRevokesExactly() {
        Challenge c = Challenge.create(UUID.randomUUID(), UUID.randomUUID(), details(Difficulty.HIGH), List.of(), NOW);

        ChallengeChanges first = c.complete(TODAY);
        assertThat(first.xpDelta()).isEqualTo(70);
        assertThat(first.challengeCompleted()).isTrue();
        assertThat(c.xpAwarded()).isEqualTo(70);

        assertThat(c.complete(TODAY).xpDelta()).isZero();

        // Cambiar la dificultad tras completar no altera lo que se resta: el XP exacto otorgado.
        c.updateDetails(new ChallengeDetails(c.title(), c.type(), c.goal(), c.visibility(), Difficulty.LOW,
                c.startAt(), c.endAt(), null, null));
        assertThat(c.uncomplete().xpDelta()).isEqualTo(-70);
        assertThat(c.xpAwarded()).isZero();
        assertThat(c.uncomplete().xpDelta()).isZero();
        assertThat(c.complete(TODAY).xpDelta()).isEqualTo(20);
    }

    @Test
    void difficultyXpFollowsLegacyRule() {
        assertThat(Difficulty.LOW.xp()).isEqualTo(20);
        assertThat(Difficulty.MEDIUM.xp()).isEqualTo(40);
        assertThat(Difficulty.HIGH.xp()).isEqualTo(70);
    }

    @Test
    void challengeWithTasksCompletesWhenAllTasksAreDoneAndXpComesFromTasks() {
        Challenge c = withTasks(task("Tarea uno"), task("Tarea dos"));
        UUID a = c.milestones().get(0).id();
        UUID b = c.milestones().get(1).id();

        ChallengeChanges first = c.completeMilestone(a, TODAY, false);
        assertThat(first.xpDelta()).isEqualTo(40);
        assertThat(c.completed()).isFalse();
        assertThat(c.progress()).isEqualTo(50.0);

        ChallengeChanges second = c.completeMilestone(b, TODAY, false);
        assertThat(second.challengeCompleted()).isTrue();
        assertThat(c.completed()).isTrue();
        assertThat(c.progress()).isEqualTo(100.0);
        assertThat(c.xpAwarded()).isZero();

        ChallengeChanges undo = c.uncompleteMilestone(a);
        assertThat(undo.xpDelta()).isEqualTo(-40);
        assertThat(undo.challengeUncompleted()).isTrue();
        assertThat(c.completed()).isFalse();
    }

    @Test
    void completingChallengeCompletesPendingTasksAndUncompletingRevokesAll() {
        Challenge c = withTasks(task("Tarea uno"), task("Tarea dos"), task("Tarea tres"));
        c.completeMilestone(c.milestones().get(0).id(), TODAY, false);

        assertThat(c.complete(TODAY).xpDelta()).isEqualTo(80);
        assertThat(c.milestones()).allMatch(Milestone::completed);

        assertThat(c.uncomplete().xpDelta()).isEqualTo(-120);
        assertThat(c.milestones()).noneMatch(Milestone::completed);
        assertThat(c.progress()).isZero();
        assertThat(c.totalXpAwarded()).isZero();
    }

    @Test
    void addingTasksToCompletedChallengeRevokesItsOwnXp() {
        Challenge c = Challenge.create(UUID.randomUUID(), UUID.randomUUID(), details(Difficulty.MEDIUM), List.of(), NOW);
        c.complete(TODAY);

        ChallengeChanges changes = c.replaceMilestones(List.of(task("Nueva tarea")));

        assertThat(changes.xpDelta()).isEqualTo(-40);
        assertThat(changes.challengeUncompleted()).isTrue();
        assertThat(c.completed()).isFalse();
        assertThat(c.xpAwarded()).isZero();
    }

    @Test
    void replacingKeepsProgressOfKeptTasksAndRevokesXpOfRemovedOnes() {
        Challenge c = withTasks(task("Tarea uno"), task("Tarea dos"));
        Milestone first = c.milestones().get(0);
        Milestone second = c.milestones().get(1);
        c.completeMilestone(first.id(), TODAY, false);
        c.completeMilestone(second.id(), TODAY, false);

        ChallengeChanges changes = c.replaceMilestones(List.of(
                new MilestoneDraft(first.id(), "Tarea uno editada", null, Difficulty.MEDIUM, null, null, null, null,
                        List.of(), null, null),
                task("Tarea nueva")));

        assertThat(changes.xpDelta()).isEqualTo(-40);
        assertThat(c.milestones()).hasSize(2);
        assertThat(c.milestone(first.id()).completed()).isTrue();
        assertThat(c.milestone(first.id()).title()).isEqualTo("Tarea uno editada");
        assertThat(c.completed()).isFalse();
    }

    // ---------------------------------------------------------------- pesos

    @Test
    void weightsAreSplitEvenlyWhenOmittedAndAddUpTo100() {
        Challenge c = withTasks(task("Tarea uno"), task("Tarea dos"), task("Tarea tres"));
        assertThat(c.milestones()).extracting(Milestone::weight).containsExactly(33.33, 33.33, 33.34);
        assertThat(c.milestones().stream().mapToDouble(Milestone::weight).sum()).isCloseTo(100.0,
                org.assertj.core.data.Offset.offset(0.0001));
    }

    @Test
    void explicitWeightsMustAddUpTo100() {
        assertThatThrownBy(() -> withTasks(task("Tarea uno", 50.0, List.of(), null, null),
                task("Tarea dos", 40.0, List.of(), null, null)))
                .isInstanceOf(InvalidMilestoneWeightsException.class)
                .extracting(e -> ((DomainException) e).code()).isEqualTo("MILESTONE_WEIGHTS_INVALID");

        Challenge ok = withTasks(task("Tarea uno", 70.0, List.of(), null, null),
                task("Tarea dos", 30.0, List.of(), null, null));
        assertThat(ok.milestones()).extracting(Milestone::weight).containsExactly(70.0, 30.0);
    }

    @Test
    void weightsMustBeGivenForAllTasksOrNone() {
        assertThatThrownBy(() -> withTasks(task("Tarea uno", 100.0, List.of(), null, null), task("Tarea dos")))
                .isInstanceOf(InvalidMilestoneWeightsException.class);
    }

    @Test
    void weightedProgressUsesTaskWeights() {
        Challenge c = withTasks(task("Tarea uno", 75.0, List.of(), null, null),
                task("Tarea dos", 25.0, List.of(), null, null));
        c.addProgress(c.milestones().get(0).id(), 50, TODAY);
        assertThat(c.progress()).isEqualTo(37.5);
    }

    @Test
    void aChallengeNeverGivesMoreThanItsXpCap() {
        List<MilestoneDraft> drafts = new ArrayList<>();
        IntStream.range(0, 12).forEach(i -> drafts.add(new MilestoneDraft(null, "Tarea " + i, null, Difficulty.HIGH,
                null, null, null, null, List.of(), null, null)));
        Challenge c = withTasks(drafts.toArray(MilestoneDraft[]::new));

        // 12 tareas difíciles daban 12 × 70 = 840 XP; ahora el reto entero da como mucho MAX_XP.
        assertThat(c.complete(TODAY).xpDelta()).isEqualTo(Challenge.MAX_XP);
        assertThat(c.totalXpAwarded()).isEqualTo(Challenge.MAX_XP);
        assertThat(c.uncomplete().xpDelta()).isEqualTo(-Challenge.MAX_XP);
    }

    @Test
    void atMostTwelveTasks() {
        List<MilestoneDraft> drafts = new ArrayList<>();
        IntStream.range(0, 13).forEach(i -> drafts.add(task("Tarea " + i)));
        assertThatThrownBy(() -> withTasks(drafts.toArray(MilestoneDraft[]::new)))
                .isInstanceOf(TooManyMilestonesException.class);
    }

    @Test
    void endMustBeAfterStart() {
        assertThatThrownBy(() -> Challenge.create(UUID.randomUUID(), UUID.randomUUID(),
                new ChallengeDetails("Titulo valido", null, null, null, null, NOW, NOW, null, null), List.of(), NOW))
                .isInstanceOf(InvalidChallengeDatesException.class);
    }

    @Test
    void typeIsDerivedFromSubject() {
        Challenge c = Challenge.create(UUID.randomUUID(), UUID.randomUUID(),
                new ChallengeDetails("Repasar temas", null, null, null, null, NOW, NOW.plusSeconds(3600),
                        UUID.randomUUID(), null), List.of(task("Tarea uno")), NOW);
        assertThat(c.type()).isEqualTo(ChallengeType.ACADEMIC);
        assertThat(c.goal()).isEqualTo("Repasar temas");
        assertThat(c.milestones().getFirst().subjectId()).isEqualTo(c.subjectId());
    }

    // ---------------------------------------------------------------- dependencias

    @Test
    void andConditionUnlocksWhenAllDependenciesAreCompleted() {
        Challenge c = withTasks(task("Base A"), task("Base B"), task("Final", null, List.of(0, 1), UnlockCondition.AND, null));
        Milestone fin = c.milestones().get(2);
        assertThat(fin.status()).isEqualTo(MilestoneStatus.LOCKED);
        assertThat(c.milestones().get(0).status()).isEqualTo(MilestoneStatus.AVAILABLE);

        assertThatThrownBy(() -> c.completeMilestone(fin.id(), TODAY, false))
                .isInstanceOf(MilestoneLockedException.class);

        assertThat(c.completeMilestone(c.milestones().get(0).id(), TODAY, false).unlockedMilestoneIds()).isEmpty();
        assertThat(c.completeMilestone(c.milestones().get(1).id(), TODAY, false).unlockedMilestoneIds())
                .containsExactly(fin.id());
        assertThat(c.milestone(fin.id()).status()).isEqualTo(MilestoneStatus.AVAILABLE);
        assertThat(c.hasDependencies()).isTrue();
    }

    @Test
    void orConditionUnlocksWithAnyDependency() {
        Challenge c = withTasks(task("Base A"), task("Base B"), task("Final", null, List.of(0, 1), UnlockCondition.OR, null));
        UUID fin = c.milestones().get(2).id();
        assertThat(c.completeMilestone(c.milestones().get(1).id(), TODAY, false).unlockedMilestoneIds())
                .containsExactly(fin);
    }

    @Test
    void xOfYConditionUnlocksWithNDependencies() {
        Challenge c = withTasks(task("Base A"), task("Base B"), task("Base C"),
                task("Final", null, List.of(0, 1, 2), UnlockCondition.X_OF_Y, 2));
        UUID fin = c.milestones().get(3).id();
        c.completeMilestone(c.milestones().get(0).id(), TODAY, false);
        assertThat(c.milestone(fin).isLocked()).isTrue();
        c.completeMilestone(c.milestones().get(2).id(), TODAY, false);
        assertThat(c.milestone(fin).isLocked()).isFalse();

        // Si una dependencia vuelve atrás, la tarea pendiente vuelve a bloquearse.
        c.uncompleteMilestone(c.milestones().get(0).id());
        assertThat(c.milestone(fin).isLocked()).isTrue();
    }

    @Test
    void forcedCompletionIgnoresLock() {
        Challenge c = withTasks(task("Base A"), task("Final", null, List.of(0), UnlockCondition.AND, null));
        UUID fin = c.milestones().get(1).id();
        assertThat(c.completeMilestone(fin, TODAY, true).xpDelta()).isEqualTo(40);
    }

    @Test
    void invalidDependenciesAreRejected() {
        assertThatThrownBy(() -> withTasks(task("Tarea uno", null, List.of(0), null, null)))
                .isInstanceOf(InvalidMilestoneDependencyException.class);
        assertThatThrownBy(() -> withTasks(task("Tarea uno", null, List.of(5), null, null)))
                .isInstanceOf(InvalidMilestoneDependencyException.class);
        assertThatThrownBy(() -> withTasks(task("Tarea uno", null, List.of(1), null, null),
                task("Tarea dos", null, List.of(0), null, null)))
                .isInstanceOf(InvalidMilestoneDependencyException.class)
                .hasMessageContaining("cycle");
        assertThatThrownBy(() -> withTasks(task("Tarea uno"),
                task("Tarea dos", null, List.of(0), UnlockCondition.X_OF_Y, 2)))
                .isInstanceOf(InvalidMilestoneDependencyException.class);
    }

    // ---------------------------------------------------------------- progreso y racha

    @Test
    void progressCompletesTaskAtHundred() {
        Challenge c = withTasks(task("Tarea uno"), task("Tarea dos"));
        UUID a = c.milestones().get(0).id();
        assertThat(c.addProgress(a, 60, TODAY).xpDelta()).isZero();
        assertThat(c.milestone(a).status()).isEqualTo(MilestoneStatus.IN_PROGRESS);
        assertThat(c.addProgress(a, 60, TODAY).xpDelta()).isEqualTo(40);
        assertThat(c.milestone(a).completed()).isTrue();
    }

    @Test
    void manualProgressWithoutTasksCompletesChallenge() {
        Challenge c = Challenge.create(UUID.randomUUID(), UUID.randomUUID(), details(Difficulty.LOW), List.of(), NOW);
        c.addProgress(null, 40, TODAY);
        assertThat(c.progress()).isEqualTo(40.0);
        ChallengeChanges done = c.addProgress(null, 60, TODAY);
        assertThat(done.xpDelta()).isEqualTo(20);
        assertThat(c.completed()).isTrue();
    }

    @Test
    void progressOnChallengeWithTasksNeedsMilestone() {
        Challenge c = withTasks(task("Tarea uno"));
        assertThatThrownBy(() -> c.addProgress(null, 10, TODAY)).isInstanceOf(ProgressMilestoneRequiredException.class);
    }

    @Test
    void streakCountsConsecutiveActiveDays() {
        Challenge c = withTasks(task("Tarea uno"), task("Tarea dos"));
        UUID a = c.milestones().get(0).id();
        c.addProgress(a, 10, TODAY);
        c.addProgress(a, 10, TODAY);
        c.addProgress(a, 10, TODAY.plusDays(1));
        assertThat(c.currentStreak()).isEqualTo(2);
        c.addProgress(a, 10, TODAY.plusDays(5));
        assertThat(c.currentStreak()).isEqualTo(1);
        assertThat(c.bestStreak()).isEqualTo(2);
        assertThat(c.lastActiveDay()).isEqualTo(TODAY.plusDays(5));
    }

    @Test
    void studyBlockProgressCompletesAndUncompletesTask() {
        Challenge c = withTasks(task("Tarea uno"), task("Tarea dos"));
        UUID a = c.milestones().get(0).id();
        assertThat(c.applyStudyBlockProgress(a, 50, TODAY).xpDelta()).isZero();
        assertThat(c.applyStudyBlockProgress(a, 50, TODAY).xpDelta()).isZero();
        assertThat(c.applyStudyBlockProgress(a, 100, TODAY).xpDelta()).isEqualTo(40);
        assertThat(c.applyStudyBlockProgress(a, 100, TODAY).xpDelta()).isZero();
        assertThat(c.applyStudyBlockProgress(a, 50, TODAY).xpDelta()).isEqualTo(-40);
        assertThat(c.milestone(a).progress()).isEqualTo(50.0);
    }

    @Test
    void linkChangesAreReportedOnlyForExamsAndDeliveries() {
        UUID exam = UUID.randomUUID();
        Challenge c = Challenge.create(UUID.randomUUID(), UUID.randomUUID(),
                new ChallengeDetails("Preparar examen", null, null, null, null, NOW, NOW.plusSeconds(3600), null,
                        new ChallengeLink(LinkType.EXAM, exam)),
                List.of(new MilestoneDraft(null, "Bloque vinculado", null, null, null, null, null,
                        new ChallengeLink(LinkType.BLOCK, UUID.randomUUID()), List.of(), null, null)), NOW);
        ChallengeChanges changes = c.complete(TODAY);
        assertThat(changes.linkChanges()).extracting(l -> l.link().entityId()).containsExactly(exam);
        assertThat(changes.linkChanges().getFirst().completed()).isTrue();
    }

    @Test
    void cloneCopiesTasksAndDependenciesAsPrivateWithoutProgress() {
        Challenge c = withTasks(task("Base A"), task("Final", null, List.of(0), UnlockCondition.AND, null));
        c.complete(TODAY);
        UUID newOwner = UUID.randomUUID();
        Challenge copy = c.cloneFor(UUID.randomUUID(), newOwner, "Ana", NOW);
        assertThat(copy.ownerId()).isEqualTo(newOwner);
        assertThat(copy.visibility()).isEqualTo(Visibility.PRIVATE);
        assertThat(copy.originId()).isEqualTo(c.id());
        assertThat(copy.originOwnerName()).isEqualTo("Ana");
        assertThat(copy.completed()).isFalse();
        assertThat(copy.milestones()).hasSize(2).noneMatch(Milestone::completed);
        assertThat(copy.milestones().get(1).dependencies()).containsExactly(copy.milestones().get(0).id());
        assertThat(copy.milestones().get(1).isLocked()).isTrue();
    }
}
