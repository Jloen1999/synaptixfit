package com.synaptixfit.application.service.planner;

import static com.synaptixfit.application.service.planner.PlannerFakes.at;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.application.port.input.planner.CreateDeadlineUseCase;
import com.synaptixfit.application.port.input.planner.RecordFocusSessionUseCase;
import com.synaptixfit.application.port.input.planner.SuggestWeekPlanUseCase;
import com.synaptixfit.domain.event.planner.DeadlineCompletionChanged;
import com.synaptixfit.domain.event.planner.FocusSessionCompleted;
import com.synaptixfit.domain.event.planner.StudyBlockCompletionChanged;
import com.synaptixfit.domain.exception.planner.CalendarBlockNotFoundException;
import com.synaptixfit.domain.exception.planner.BlockRoutineLinkedException;
import com.synaptixfit.domain.model.planner.ActivityType;
import com.synaptixfit.domain.model.planner.CalendarBlock;
import com.synaptixfit.domain.model.planner.Deadline;
import com.synaptixfit.domain.model.planner.DeadlineType;
import com.synaptixfit.domain.model.planner.FocusRewards;
import com.synaptixfit.domain.model.planner.FocusSession;
import com.synaptixfit.domain.model.planner.FocusXpStatus;
import com.synaptixfit.domain.model.planner.PlannerProfile;
import com.synaptixfit.domain.model.planner.PlanningInbox;
import com.synaptixfit.domain.model.planner.Priority;
import com.synaptixfit.domain.model.planner.StudyPlan;
import com.synaptixfit.domain.model.planner.SubjectRef;
import com.synaptixfit.domain.model.planner.TimeRange;
import com.synaptixfit.domain.model.planner.WeeklyAcademicLoad;
import com.synaptixfit.domain.model.shared.Visibility;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/** Reacciones del planificador a otros módulos y deshacer coherente (XP, eventos, carga semanal). */
class PlannerCrossModuleSyncTest {

    private PlannerFakes f;
    private WeeklyLoadService loads;
    private BlockCompletionService completion;
    private CalendarBlockService calendar;

    @BeforeEach
    void setUp() {
        f = new PlannerFakes();
        loads = f.weeklyLoadService();
        completion = new BlockCompletionService(f.blocks, f.directory, f.directory, f.xp, f.xp, f.publisher, loads,
                PlannerFakes.ZONE, PlannerFakes.END_OF_WEEK);
        calendar = new CalendarBlockService(f.blocks, f.deadlines, f.directory, f.directory, f.directory, f.xp,
                f.publisher, loads, PlannerFakes.ZONE, PlannerFakes.CLOCK);
    }

    private CalendarBlock block(ActivityType type, Instant start, int minutes, UUID subjectId, UUID routineDayId,
                                UUID materialId) {
        return f.blocks.save(CalendarBlock.builder().id(UUID.randomUUID()).userId(f.user)
                .range(TimeRange.ofMinutes(start, minutes)).type(type)
                .details(new CalendarBlock.Details(subjectId, null, null, Priority.MEDIUM, false, null, null, null,
                        routineDayId, null, null, null))
                .studyMaterialId(materialId).build());
    }

    // ------------------------------------------------------------ deporte ↔ sesión de entrenamiento

    @Test
    void theSportBlockOfARoutineDayFollowsTheSessionWithoutBlockXp() {
        UUID day = UUID.randomUUID();
        CalendarBlock sport = block(ActivityType.SPORT, at(0, 18, 0), 60, null, day, null);
        CalendarBlock otherDay = block(ActivityType.SPORT, at(1, 18, 0), 60, null, day, null);

        completion.syncSportBlock(f.user, day, PlannerFakes.MONDAY, true);
        completion.syncSportBlock(f.user, day, PlannerFakes.MONDAY, true);

        assertThat(f.blocks.store.get(sport.id()).completed()).isTrue();
        assertThat(f.blocks.store.get(otherDay.id()).completed()).isFalse();
        assertThat(f.xp.of(f.user)).isZero();
        assertThat(f.events).hasSize(1);

        completion.syncSportBlock(f.user, day, PlannerFakes.MONDAY, false);
        assertThat(f.blocks.store.get(sport.id()).completed()).isFalse();
    }

    @Test
    void aSportBlockLinkedToARoutineDayCannotBeCompletedByHand() {
        CalendarBlock sport = block(ActivityType.SPORT, at(0, 18, 0), 60, null, UUID.randomUUID(), null);
        CalendarBlock free = block(ActivityType.SPORT, at(0, 20, 0), 60, null, null, null);

        // Lo marca la sesión de entrenamiento (ADR 0026), nunca la mano: así no hay XP ni carga duplicadas.
        assertThatThrownBy(() -> completion.setCompletion(f.user, sport.id(), true))
                .isInstanceOf(BlockRoutineLinkedException.class);
        assertThat(f.blocks.store.get(sport.id()).completed()).isFalse();
        assertThat(completion.setCompletion(f.user, free.id(), true).xpDelta()).isEqualTo(20);
    }

    // ------------------------------------------------------------ repaso SM-2 ↔ bloque de repaso

    @Test
    void aReviewCompletesTodaysPendingReviewBlockButNotAFutureOne() {
        UUID material = UUID.randomUUID();
        CalendarBlock today = block(ActivityType.REVIEW, at(0, 17, 0), 30, null, null, material);
        CalendarBlock future = block(ActivityType.REVIEW, at(3, 17, 0), 30, null, null, material);
        // «Hoy» es el lunes de PlannerFakes.NOW (el repaso se hace hoy).
        BlockCompletionService completion = new BlockCompletionService(f.blocks, f.directory, f.directory, f.xp,
                f.xp, f.publisher, loads, PlannerFakes.ZONE, PlannerFakes.CLOCK);

        completion.completeReviewBlock(f.user, material);

        assertThat(f.blocks.store.get(today.id()).completed()).isTrue();
        assertThat(f.blocks.store.get(future.id()).completed()).isFalse();
        // La XP la da el repaso SM-2, no el bloque.
        assertThat(f.xp.of(f.user)).isZero();
        assertThat(f.events).singleElement().isInstanceOf(StudyBlockCompletionChanged.class);

        f.events.clear();
        completion.completeReviewBlock(f.user, UUID.randomUUID());
        assertThat(f.events).isEmpty();
    }

    // ------------------------------------------------------------ deshacer

    @Test
    void deletingACompletedDeadlinePublishesItsUncompletionForLinkedChallenges() {
        DeadlineService deadlines = new DeadlineService(f.deadlines, f.directory, f.xp, f.xp, f.publisher, loads,
                PlannerFakes.ZONE, PlannerFakes.CLOCK);
        Deadline pending = deadlines.createDeadline(new CreateDeadlineUseCase.Command(f.user, "Pendiente",
                DeadlineType.ASSIGNMENT, at(2, 12, 0), Priority.MEDIUM, null, null));
        Deadline done = deadlines.createDeadline(new CreateDeadlineUseCase.Command(f.user, "Hecha",
                DeadlineType.ASSIGNMENT, at(3, 12, 0), Priority.MEDIUM, null, null));
        deadlines.setCompletion(f.user, done.id(), true);
        f.events.clear();

        deadlines.deleteDeadline(f.user, pending.id());
        assertThat(f.events).isEmpty();

        deadlines.deleteDeadline(f.user, done.id());
        assertThat(f.events).singleElement().isInstanceOfSatisfying(DeadlineCompletionChanged.class, e -> {
            assertThat(e.deadlineId()).isEqualTo(done.id());
            assertThat(e.completed()).isFalse();
        });
        assertThat(f.xp.of(f.user)).isZero();
    }

    @Test
    void deletingASubjectsBlocksRevokesTheirXpAndPublishesUncompletion() {
        SubjectRef subject = f.directory.addSubject(f.user, "Física", "FIS", 3);
        CalendarBlock done = block(ActivityType.STUDY, at(1, 10, 0), 60, subject.id(), null, null);
        block(ActivityType.STUDY, at(2, 10, 0), 60, subject.id(), null, null);
        CalendarBlock other = block(ActivityType.STUDY, at(2, 12, 0), 60, null, null, null);
        completion.setCompletion(f.user, done.id(), true);
        f.events.clear();

        calendar.deleteSubjectBlocks(f.user, subject.id());

        assertThat(f.blocks.store).containsOnlyKeys(other.id());
        assertThat(f.xp.of(f.user)).isZero();
        assertThat(f.events).singleElement().isInstanceOfSatisfying(StudyBlockCompletionChanged.class,
                e -> assertThat(e.completed()).isFalse());
    }

    @Test
    void theWeeklyStudyBonusIsRevokedWhenTheWeekDropsBelowTheGoal() {
        f.directory.academic.put(f.user, new PlannerProfile.Academic(2, null, null));
        CalendarBlock study = block(ActivityType.STUDY, at(1, 10, 0), 120, null, null, null);
        completion.setCompletion(f.user, study.id(), true);
        assertThat(f.xp.of(f.user)).isEqualTo(40 + WeeklyAcademicLoad.STUDY_EXPERIENCE);

        completion.setCompletion(f.user, study.id(), false);
        assertThat(f.xp.of(f.user)).isZero();
        assertThat(loads.syncWeek(f.user, PlannerFakes.MONDAY).xpAwarded()).isZero();
        assertThat(f.xp.of(f.user)).isZero();
    }

    // ------------------------------------------------------------ Pomodoro

    @Test
    void focusXpHasADailyCapAndOnlyCompletedFocusPhasesPublish() {
        FocusService focus = new FocusService(f.focus, f.blocks, f.directory, f.xp, f.publisher, f.weeklyLoadService(),
                PlannerFakes.ZONE,
                PlannerFakes.CLOCK);
        List<Integer> xps = new ArrayList<>();
        List<FocusXpStatus> statuses = new ArrayList<>();
        for (int i = 0; i < 6; i++) {
            RecordFocusSessionUseCase.Result result = focus.record(new RecordFocusSessionUseCase.Command(f.user,
                    FocusSession.FocusPhase.FOCUS, 25, 1, true, null, null, null));
            xps.add(result.session().xpAwarded());
            statuses.add(result.xpStatus());
        }
        assertThat(xps).containsExactly(5, 5, 5, 5, 0, 0);
        assertThat(statuses).containsExactly(FocusXpStatus.AWARDED, FocusXpStatus.AWARDED, FocusXpStatus.AWARDED,
                FocusXpStatus.AWARDED, FocusXpStatus.DAILY_CAP_REACHED, FocusXpStatus.DAILY_CAP_REACHED);
        assertThat(f.xp.of(f.user)).isEqualTo(FocusRewards.DAILY_CAP);
        assertThat(f.events).hasSize(6).allMatch(FocusSessionCompleted.class::isInstance);

        f.events.clear();
        assertThat(focus.record(new RecordFocusSessionUseCase.Command(f.user, FocusSession.FocusPhase.SHORT_BREAK, 5,
                1, true, null, null, null)).xpStatus()).isEqualTo(FocusXpStatus.NOT_ELIGIBLE);
        assertThat(f.events).isEmpty();
    }

    @Test
    void focusInAnOwnBlockTakesItsSubjectAndDoesNotCompleteIt() {
        FocusService focus = new FocusService(f.focus, f.blocks, f.directory, f.xp, f.publisher, f.weeklyLoadService(),
                PlannerFakes.ZONE,
                PlannerFakes.CLOCK);
        SubjectRef subject = f.directory.addSubject(f.user, "Física", "FIS", 3);
        CalendarBlock study = block(ActivityType.STUDY, at(0, 9, 0), 60, subject.id(), null, null);

        RecordFocusSessionUseCase.Result pastResult = focus.record(new RecordFocusSessionUseCase.Command(f.user,
                FocusSession.FocusPhase.FOCUS, 25, 1, true, PlannerFakes.MONDAY.minusDays(1), study.id(), null));
        FocusSession past = pastResult.session();
        assertThat(pastResult.xpStatus()).isEqualTo(FocusXpStatus.NOT_ELIGIBLE);

        assertThat(past.subjectId()).isEqualTo(subject.id());
        assertThat(past.xpAwarded()).isZero();
        assertThat(f.blocks.store.get(study.id()).completed()).isFalse();
        CalendarBlock foreign = f.blocks.save(CalendarBlock.builder().id(UUID.randomUUID()).userId(f.otherUser)
                .range(TimeRange.ofMinutes(at(0, 9, 0), 60)).type(ActivityType.STUDY).build());
        assertThatThrownBy(() -> focus.record(new RecordFocusSessionUseCase.Command(f.user,
                FocusSession.FocusPhase.FOCUS, 25, 1, true, null, foreign.id(), null)))
                .isInstanceOf(CalendarBlockNotFoundException.class);
    }

    // ------------------------------------------------------------ regulación cruzada y privacidad

    @Test
    void crossRegulationCapsTheStudyBlockLengthOfTheSuggestions() {
        List<PlanningInbox> seen = new ArrayList<>();
        PlanningSuggestionService service = new PlanningSuggestionService((inbox, zone) -> {
            seen.add(inbox);
            return List.of();
        }, f.directory, f.deadlines, f.directory, f.blocks, f.crossRegulation, PlannerFakes.ZONE, PlannerFakes.CLOCK);

        f.crossRegulationMaxStudyMinutes = 60;
        service.suggest(new SuggestWeekPlanUseCase.Command(f.user, PlannerFakes.MONDAY, 5, 0, 60, 90));
        f.crossRegulationMaxStudyMinutes = 25;
        service.suggest(new SuggestWeekPlanUseCase.Command(f.user, PlannerFakes.MONDAY, 5, 0, 60, 90));

        assertThat(seen).extracting(PlanningInbox::maxStudyBlockMinutes).containsExactly(60, 30);
    }

    @Test
    void privatizingStudyPlansIsIdempotent() {
        StudyPlanService plans = new StudyPlanService(f.plans, f.blocks, f.deadlines, f.xp, f.xp, PlannerFakes.ZONE);
        f.plans.save(new StudyPlan(UUID.randomUUID(), f.user, "Plan", PlannerFakes.MONDAY, Visibility.PUBLIC, false, 0));
        f.plans.save(new StudyPlan(UUID.randomUUID(), f.user, "Plan 2", PlannerFakes.MONDAY.plusDays(7),
                Visibility.PRIVATE, false, 0));

        assertThat(plans.privatizeAll(f.user)).isEqualTo(1);
        assertThat(plans.privatizeAll(f.user)).isZero();
        assertThat(f.plans.store.values()).allMatch(p -> p.visibility() == Visibility.PRIVATE);
    }
}
