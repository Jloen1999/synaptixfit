package com.synaptixfit.domain.model.challenge;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.domain.exception.DomainException;
import com.synaptixfit.domain.exception.challenge.InvalidChallengeDatesException;
import com.synaptixfit.domain.exception.challenge.InvalidMilestoneDependencyException;
import com.synaptixfit.domain.exception.challenge.ChallengeExpiredException;
import com.synaptixfit.domain.exception.challenge.ChallengeLinkOutsidePeriodException;
import com.synaptixfit.domain.exception.challenge.ChallengeLinkedException;
import com.synaptixfit.domain.exception.challenge.ChallengeNotStartedException;
import com.synaptixfit.domain.exception.challenge.MilestoneLinkedException;
import com.synaptixfit.domain.exception.challenge.MilestoneLockedException;
import com.synaptixfit.domain.exception.challenge.ProgressMilestoneRequiredException;
import com.synaptixfit.domain.exception.challenge.TooManyMilestonesException;
import com.synaptixfit.domain.model.shared.Visibility;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.IntStream;
import org.junit.jupiter.api.Test;

/** Reglas del agregado reto: XP con anti-farmeo y tope, pesos, dependencias, periodo, vínculos, progreso y racha. */
class ChallengeTest {

    private static final Instant NOW = Instant.parse("2026-10-01T10:00:00Z");
    private static final LocalDate TODAY = LocalDate.parse("2026-10-01");

    static ChallengeDetails details(Difficulty difficulty) {
        return new ChallengeDetails("Leer 3 capítulos", null, null, Visibility.PRIVATE, difficulty, NOW,
                NOW.plusSeconds(86_400 * 7), null, null);
    }

    static MilestoneDraft task(String title, Difficulty difficulty, List<Integer> deps, UnlockCondition cond,
                               Integer n) {
        return new MilestoneDraft(null, title, difficulty, null, null, null, null, deps, cond, n);
    }

    static MilestoneDraft task(String title) {
        return task(title, Difficulty.MEDIUM, List.of(), null, null);
    }

    static MilestoneDraft linkedTask(String title, UUID deadlineId) {
        return new MilestoneDraft(null, title, Difficulty.MEDIUM, null, null, null,
                new ChallengeLink(LinkType.DELIVERY, deadlineId), List.of(), null, null);
    }

    /** Reconstruye el reto como lo cargaría la persistencia, con la foto de sus entregas y bloques. */
    private static Challenge reload(Challenge c, Map<UUID, LinkedDeadline> deadlines,
                                    Map<UUID, StudyBlockProgress> blocks) {
        return Challenge.builder().id(c.id()).ownerId(c.ownerId()).title(c.title()).type(c.type()).goal(c.goal())
                .visibility(c.visibility()).completed(c.completed()).startAt(c.startAt()).endAt(c.endAt())
                .createdAt(c.createdAt()).difficulty(c.difficulty()).link(c.link()).xpAwarded(c.xpAwarded())
                .manualProgress(c.manualProgress()).milestones(c.milestones()).linkedDeadlines(deadlines)
                .studyBlocks(blocks).build();
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

        ChallengeChanges first = c.completeMilestone(a, TODAY);
        assertThat(first.xpDelta()).isEqualTo(40);
        assertThat(c.completed()).isFalse();
        assertThat(c.progress()).isEqualTo(50.0);

        ChallengeChanges second = c.completeMilestone(b, TODAY);
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
        c.completeMilestone(c.milestones().get(0).id(), TODAY);

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
        c.completeMilestone(first.id(), TODAY);
        c.completeMilestone(second.id(), TODAY);

        ChallengeChanges changes = c.replaceMilestones(List.of(
                new MilestoneDraft(first.id(), "Tarea uno editada", Difficulty.MEDIUM, null, null, null, null,
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
    void weightsComeFromDifficultyAndAddUpTo100() {
        Challenge even = withTasks(task("Tarea uno"), task("Tarea dos"), task("Tarea tres"));
        assertThat(even.milestones()).extracting(Milestone::weight).containsExactly(33.33, 33.33, 33.34);

        // Baja 20, media 40, alta 70: una sola medida de importancia (ADR 0028).
        Challenge mixed = withTasks(task("Tarea fácil", Difficulty.LOW, List.of(), null, null),
                task("Tarea difícil", Difficulty.HIGH, List.of(), null, null));
        assertThat(mixed.milestones()).extracting(Milestone::weight).containsExactly(22.22, 77.78);
        assertThat(mixed.milestones().stream().mapToDouble(Milestone::weight).sum()).isCloseTo(100.0,
                org.assertj.core.data.Offset.offset(0.0001));
    }

    @Test
    void weightedProgressUsesDifficultyWeights() {
        Challenge c = withTasks(task("Tarea difícil", Difficulty.HIGH, List.of(), null, null),
                task("Tarea fácil", Difficulty.LOW, List.of(), null, null));
        c.setProgress(c.milestones().get(0).id(), 50, TODAY);
        assertThat(c.progress()).isEqualTo(38.89);
    }

    @Test
    void xpShownPerTaskHonoursTheCap() {
        Challenge c = withTasks(task("Difícil uno", Difficulty.HIGH, List.of(), null, null),
                task("Difícil dos", Difficulty.HIGH, List.of(), null, null),
                task("Difícil tres", Difficulty.HIGH, List.of(), null, null));
        // 3 × 70 = 210, pero el reto da como mucho 140: la tercera no daría nada.
        assertThat(c.milestoneXp().values()).containsExactly(70, 70, 0);
        assertThat(c.xpReward()).isEqualTo(Challenge.MAX_XP);
    }

    @Test
    void aChallengeNeverGivesMoreThanItsXpCap() {
        List<MilestoneDraft> drafts = new ArrayList<>();
        IntStream.range(0, 12).forEach(i -> drafts.add(new MilestoneDraft(null, "Tarea " + i, Difficulty.HIGH,
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
        Challenge c = withTasks(task("Base A"), task("Base B"), task("Final", Difficulty.MEDIUM, List.of(0, 1), UnlockCondition.AND, null));
        Milestone fin = c.milestones().get(2);
        assertThat(fin.status()).isEqualTo(MilestoneStatus.LOCKED);
        assertThat(c.milestones().get(0).status()).isEqualTo(MilestoneStatus.AVAILABLE);

        assertThatThrownBy(() -> c.completeMilestone(fin.id(), TODAY))
                .isInstanceOf(MilestoneLockedException.class);

        assertThat(c.completeMilestone(c.milestones().get(0).id(), TODAY).unlockedMilestoneIds()).isEmpty();
        assertThat(c.completeMilestone(c.milestones().get(1).id(), TODAY).unlockedMilestoneIds())
                .containsExactly(fin.id());
        assertThat(c.milestone(fin.id()).status()).isEqualTo(MilestoneStatus.AVAILABLE);
        assertThat(c.hasDependencies()).isTrue();
    }

    @Test
    void orConditionUnlocksWithAnyDependency() {
        Challenge c = withTasks(task("Base A"), task("Base B"), task("Final", Difficulty.MEDIUM, List.of(0, 1), UnlockCondition.OR, null));
        UUID fin = c.milestones().get(2).id();
        assertThat(c.completeMilestone(c.milestones().get(1).id(), TODAY).unlockedMilestoneIds())
                .containsExactly(fin);
    }

    @Test
    void xOfYConditionUnlocksWithNDependencies() {
        Challenge c = withTasks(task("Base A"), task("Base B"), task("Base C"),
                task("Final", Difficulty.MEDIUM, List.of(0, 1, 2), UnlockCondition.X_OF_Y, 2));
        UUID fin = c.milestones().get(3).id();
        c.completeMilestone(c.milestones().get(0).id(), TODAY);
        assertThat(c.milestone(fin).isLocked()).isTrue();
        c.completeMilestone(c.milestones().get(2).id(), TODAY);
        assertThat(c.milestone(fin).isLocked()).isFalse();

        // Si una dependencia vuelve atrás, la tarea pendiente vuelve a bloquearse.
        c.uncompleteMilestone(c.milestones().get(0).id());
        assertThat(c.milestone(fin).isLocked()).isTrue();
    }

    @Test
    void deadlineCompletionIgnoresLock() {
        UUID delivery = UUID.randomUUID();
        Challenge c = withTasks(task("Base A"), new MilestoneDraft(null, "Final", Difficulty.MEDIUM, null, null, null,
                new ChallengeLink(LinkType.DELIVERY, delivery), List.of(0), UnlockCondition.AND, null));
        assertThat(c.applyDeadline(delivery, true, TODAY).xpDelta()).isEqualTo(40);
    }

    @Test
    void invalidDependenciesAreRejected() {
        assertThatThrownBy(() -> withTasks(task("Tarea uno", Difficulty.MEDIUM, List.of(0), null, null)))
                .isInstanceOf(InvalidMilestoneDependencyException.class);
        assertThatThrownBy(() -> withTasks(task("Tarea uno", Difficulty.MEDIUM, List.of(5), null, null)))
                .isInstanceOf(InvalidMilestoneDependencyException.class);
        assertThatThrownBy(() -> withTasks(task("Tarea uno", Difficulty.MEDIUM, List.of(1), null, null),
                task("Tarea dos", Difficulty.MEDIUM, List.of(0), null, null)))
                .isInstanceOf(InvalidMilestoneDependencyException.class)
                .hasMessageContaining("cycle");
        assertThatThrownBy(() -> withTasks(task("Tarea uno"),
                task("Tarea dos", Difficulty.MEDIUM, List.of(0), UnlockCondition.X_OF_Y, 2)))
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
    void absoluteProgressCanBeCorrectedAndUncompleteResetsIt() {
        Challenge c = Challenge.create(UUID.randomUUID(), UUID.randomUUID(), details(Difficulty.LOW), List.of(), NOW);
        c.setProgress(null, 40, TODAY);
        c.setProgress(null, 30, TODAY);
        assertThat(c.progress()).isEqualTo(30.0);
        assertThat(c.setProgress(null, 100, TODAY).challengeCompleted()).isTrue();

        // Desmarcar no deja el 100 % a la vista con el reto activo.
        c.uncomplete();
        assertThat(c.completed()).isFalse();
        assertThat(c.progress()).isZero();
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
    void studyBlocksAreIgnoredWhenTheTaskHasADeadline() {
        UUID delivery = UUID.randomUUID();
        Challenge c = reload(withTasks(linkedTask("Entregar práctica", delivery), task("Otra tarea")),
                Map.of(delivery, new LinkedDeadline("Práctica", NOW.plusSeconds(3600), false)), Map.of());
        UUID a = c.milestones().get(0).id();
        assertThat(c.applyStudyBlockProgress(a, 100, TODAY).xpDelta()).isZero();
        assertThat(c.milestone(a).completed()).isFalse();
    }

    // ---------------------------------------------------------------- periodo (ADR 0028)

    @Test
    void cannotActBeforeStartOrAfterEnd() {
        Challenge c = Challenge.create(UUID.randomUUID(), UUID.randomUUID(), details(Difficulty.LOW), List.of(), NOW);
        assertThat(c.status(NOW.minusSeconds(60))).isEqualTo(ChallengeStatus.UPCOMING);
        assertThatThrownBy(() -> c.requireOpen(NOW.minusSeconds(60)))
                .isInstanceOf(ChallengeNotStartedException.class)
                .extracting(e -> ((DomainException) e).code()).isEqualTo("CHALLENGE_NOT_STARTED");
        c.requireOpen(NOW);

        c.complete(TODAY);
        Instant afterEnd = c.endAt().plusSeconds(60);
        // Completado y vencido: desmarcarlo ya no se permite (perdería su XP sin poder recuperarla).
        assertThat(c.status(afterEnd)).isEqualTo(ChallengeStatus.COMPLETED);
        assertThatThrownBy(() -> c.requireOpen(afterEnd)).isInstanceOf(ChallengeExpiredException.class);
        assertThatThrownBy(() -> c.requireNotEnded(afterEnd)).isInstanceOf(ChallengeExpiredException.class);
        c.requireNotEnded(NOW.minusSeconds(60));
    }

    @Test
    void linkedDeadlineMustBeDueWithinThePeriod() {
        UUID delivery = UUID.randomUUID();
        Challenge c = reload(withTasks(linkedTask("Entregar práctica", delivery)),
                Map.of(delivery, new LinkedDeadline("Práctica 2", NOW.plusSeconds(86_400 * 30), false)), Map.of());
        assertThatThrownBy(() -> c.requireLinksWithinPeriod(List.of(delivery), ZoneOffset.UTC))
                .isInstanceOf(ChallengeLinkOutsidePeriodException.class)
                .extracting(e -> ((DomainException) e).code()).isEqualTo("CHALLENGE_LINK_OUTSIDE_PERIOD");
        // Solo se comprueban los vínculos indicados (los antiguos no bloquean la edición).
        c.requireLinksWithinPeriod(List.of(), ZoneOffset.UTC);
    }

    // ---------------------------------------------------------------- fuente de verdad (ADR 0028)

    @Test
    void linkedTaskFollowsItsDeadlineAndCannotBeToggledByHand() {
        UUID delivery = UUID.randomUUID();
        Challenge created = withTasks(linkedTask("Entregar práctica", delivery), task("Repasar apuntes"));
        Challenge c = reload(created,
                Map.of(delivery, new LinkedDeadline("Práctica 2", NOW.plusSeconds(3600), true)), Map.of());
        UUID linked = c.milestones().get(0).id();
        assertThat(c.isCompletedByLink(c.milestone(linked))).isTrue();

        // Al vincular una entrega ya hecha, la tarea nace completada.
        assertThat(c.syncWithLinks(TODAY).xpDelta()).isEqualTo(40);
        assertThat(c.milestone(linked).completed()).isTrue();

        assertThatThrownBy(() -> c.uncompleteMilestone(linked)).isInstanceOf(MilestoneLinkedException.class)
                .extracting(e -> ((DomainException) e).code()).isEqualTo("MILESTONE_LINKED");

        // Completar el reto a mano solo marca las tareas manuales; desmarcarlo no toca la vinculada.
        assertThat(c.complete(TODAY).challengeCompleted()).isTrue();
        c.uncomplete();
        assertThat(c.milestone(linked).completed()).isTrue();
        assertThat(c.milestones().get(1).completed()).isFalse();

        // La entrega manda: si se desmarca, la tarea también.
        assertThat(c.applyDeadline(delivery, false, TODAY).xpDelta()).isEqualTo(-40);
    }

    @Test
    void taskWithStudyBlocksAdvancesOnlyByThem() {
        Challenge created = withTasks(task("Estudiar tema 1"), task("Estudiar tema 2"));
        UUID a = created.milestones().get(0).id();
        Challenge c = reload(created, Map.of(), Map.of(a, new StudyBlockProgress(3, 2)));
        assertThatThrownBy(() -> c.completeMilestone(a, TODAY)).isInstanceOf(MilestoneLinkedException.class);
        c.syncWithLinks(TODAY);
        assertThat(c.milestone(a).progress()).isCloseTo(66.67, org.assertj.core.data.Offset.offset(0.01));
    }

    @Test
    void linkedChallengeWithoutTasksIsCompletedByItsDeadline() {
        UUID exam = UUID.randomUUID();
        Challenge c = reload(Challenge.create(UUID.randomUUID(), UUID.randomUUID(),
                new ChallengeDetails("Preparar examen", null, null, null, Difficulty.HIGH, NOW,
                        NOW.plusSeconds(3600), null, new ChallengeLink(LinkType.EXAM, exam)), List.of(), NOW),
                Map.of(exam, new LinkedDeadline("Examen", NOW.plusSeconds(1800), false)), Map.of());
        assertThatThrownBy(() -> c.complete(TODAY)).isInstanceOf(ChallengeLinkedException.class);
        assertThat(c.applyDeadline(exam, true, TODAY).xpDelta()).isEqualTo(70);
        assertThat(c.completed()).isTrue();
    }

    @Test
    void aTaskWhoseDeadlineWasDeletedIsMarkedByHandAgain() {
        // La entrega se borró: no hay foto. La tarea no puede quedarse sin salida.
        Challenge c = reload(withTasks(linkedTask("Entregar práctica", UUID.randomUUID())), Map.of(), Map.of());
        UUID a = c.milestones().getFirst().id();
        assertThat(c.isCompletedByLink(c.milestone(a))).isFalse();
        assertThat(c.completeMilestone(a, TODAY).xpDelta()).isEqualTo(40);
    }

    @Test
    void openOnlyBetweenStartAndEnd() {
        Challenge c = Challenge.create(UUID.randomUUID(), UUID.randomUUID(), details(Difficulty.LOW), List.of(), NOW);
        assertThat(c.isOpenAt(NOW.minusSeconds(1))).isFalse();
        assertThat(c.isOpenAt(NOW)).isTrue();
        assertThat(c.isOpenAt(c.endAt().plusSeconds(1))).isFalse();
    }

    @Test
    void streakShownTodayDropsWhenADayIsMissed() {
        Challenge c = withTasks(task("Tarea uno"), task("Tarea dos"));
        c.setProgress(c.milestones().get(0).id(), 10, TODAY);
        assertThat(c.currentStreakOn(TODAY.plusDays(1))).isEqualTo(1);
        assertThat(c.currentStreakOn(TODAY.plusDays(2))).isZero();
    }

    @Test
    void cloneCopiesTasksAndDependenciesAsPrivateWithoutProgress() {
        Challenge c = withTasks(task("Base A"), task("Final", Difficulty.MEDIUM, List.of(0), UnlockCondition.AND, null));
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
