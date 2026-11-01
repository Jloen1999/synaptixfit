package com.synaptixfit.application.service.planner;

import static com.synaptixfit.application.service.planner.PlannerFakes.at;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.assertj.core.api.Assertions.within;

import com.synaptixfit.application.port.input.planner.SetBlockCompletionUseCase;
import com.synaptixfit.domain.event.planner.SportBlockCompletionChanged;
import com.synaptixfit.domain.event.planner.StudyBlockCompletionChanged;
import com.synaptixfit.domain.model.neuro.BiologicalSex;
import com.synaptixfit.domain.model.neuro.StudyEnergy;
import com.synaptixfit.domain.model.planner.ActivityType;
import com.synaptixfit.domain.model.planner.CalendarBlock;
import com.synaptixfit.domain.model.planner.ItemTimeStatus;
import com.synaptixfit.domain.model.planner.PlannerProfile;
import com.synaptixfit.domain.model.planner.Priority;
import com.synaptixfit.domain.model.planner.SubjectRef;
import com.synaptixfit.domain.model.planner.TimeRange;
import java.time.Instant;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class BlockCompletionServiceTest {

    private PlannerFakes f;
    private BlockCompletionService service;

    @BeforeEach
    void setUp() {
        f = new PlannerFakes();
        service = new BlockCompletionService(f.blocks, f.directory, f.directory, f.xp, f.xp, f.publisher,
                f.weeklyLoadService(), PlannerFakes.ZONE, PlannerFakes.END_OF_WEEK);
    }

    private CalendarBlock block(ActivityType type, Instant start, int minutes, UUID subjectId) {
        CalendarBlock b = CalendarBlock.builder().id(UUID.randomUUID()).userId(f.user)
                .range(TimeRange.ofMinutes(start, minutes)).type(type)
                .details(new CalendarBlock.Details(subjectId, null, null, Priority.MEDIUM, false, null, null, null,
                        null, null, null, null))
                .build();
        return f.blocks.save(b);
    }

    private CalendarBlock routineBlock(Instant start, UUID routineDayId) {
        return f.blocks.save(CalendarBlock.builder().id(UUID.randomUUID()).userId(f.user)
                .range(TimeRange.ofMinutes(start, 60)).type(ActivityType.SPORT)
                .details(new CalendarBlock.Details(null, "Semana 1 · Empuje", null, Priority.MEDIUM, false, null,
                        UUID.randomUUID(), UUID.randomUUID(), routineDayId, null, null, null))
                .build());
    }

    @Test
    void aRoutineBlockFollowsItsSessionEvenOnAnotherDateAndIsNotMarkedByHand() {
        UUID day = UUID.randomUUID();
        CalendarBlock wednesday = routineBlock(at(2, 18, 0), day);
        CalendarBlock nextWeek = routineBlock(at(9, 18, 0), day);

        assertThatThrownBy(() -> service.setCompletion(f.user, wednesday.id(), true))
                .extracting("code").isEqualTo("BLOCK_ROUTINE_LINKED");

        // Se entrenó el martes: se marca el bloque más cercano de ese día de rutina, sin XP de bloque.
        service.syncSportBlock(f.user, day, PlannerFakes.MONDAY.plusDays(1), true);
        assertThat(f.blocks.store.get(wednesday.id()).completed()).isTrue();
        assertThat(f.blocks.store.get(nextWeek.id()).completed()).isFalse();
        assertThat(f.xp.of(f.user)).isZero();

        service.syncSportBlock(f.user, day, PlannerFakes.MONDAY.plusDays(1), false);
        assertThat(f.blocks.store.get(wednesday.id()).completed()).isFalse();
    }

    @Test
    void completingGrantsCeilOfHalfHoursTimesTenOnlyOnce() {
        CalendarBlock b = block(ActivityType.STUDY, at(0, 16, 0), 75, null);

        SetBlockCompletionUseCase.Result first = service.setCompletion(f.user, b.id(), true);
        SetBlockCompletionUseCase.Result again = service.setCompletion(f.user, b.id(), true);

        assertThat(first.xpDelta()).isEqualTo(30);
        assertThat(again.xpDelta()).isZero();
        assertThat(f.xp.of(f.user)).isEqualTo(30);
        assertThat(f.events).hasSize(1);
        assertThat(first.block().xpAwarded()).isTrue();
    }

    @Test
    void aSportBlockWithoutRoutineReportsItsPhysicalLoad() {
        CalendarBlock football = block(ActivityType.SPORT, at(0, 16, 0), 90, null);

        service.setCompletion(f.user, football.id(), true, 7);
        service.setCompletion(f.user, football.id(), false, null);

        assertThat(f.events).filteredOn(SportBlockCompletionChanged.class::isInstance)
                .map(SportBlockCompletionChanged.class::cast)
                .satisfiesExactly(
                        done -> {
                            assertThat(done.completed()).isTrue();
                            assertThat(done.effort()).isEqualTo(7);
                            assertThat(done.durationMinutes()).isEqualTo(90);
                        },
                        undone -> assertThat(undone.completed()).isFalse());
    }

    @Test
    void studyBlocksDoNotReportPhysicalLoad() {
        CalendarBlock study = block(ActivityType.STUDY, at(0, 16, 0), 60, null);
        service.setCompletion(f.user, study.id(), true, 7);
        assertThat(f.events).noneMatch(SportBlockCompletionChanged.class::isInstance);
    }

    @Test
    void uncompletingRevokesTheSameExperienceAndClearsEnergy() {
        CalendarBlock b = block(ActivityType.STUDY, at(0, 16, 0), 60, null);
        service.setCompletion(f.user, b.id(), true);

        SetBlockCompletionUseCase.Result result = service.setCompletion(f.user, b.id(), false);

        assertThat(result.xpDelta()).isEqualTo(-20);
        assertThat(f.xp.of(f.user)).isZero();
        assertThat(result.block().metValue()).isNull();
        assertThat(result.block().cognitiveLoad()).isNull();
        assertThat(f.events).hasSize(2);
        assertThat(((StudyBlockCompletionChanged) f.events.get(1)).completed()).isFalse();
        // Desmarcar algo no completado no hace nada.
        assertThat(service.setCompletion(f.user, b.id(), false).xpDelta()).isZero();
        assertThat(f.events).hasSize(2);
    }

    @Test
    void storesCaloriesWithProfileAndCognitiveLoadWithSubjectDifficulty() {
        SubjectRef hard = f.directory.addSubject(f.user, "Cálculo", "CAL", 5);
        f.directory.metabolic.put(f.user, new PlannerProfile.Metabolic(70, 175, 21, BiologicalSex.MALE));
        CalendarBlock b = block(ActivityType.CLASS, at(0, 16, 0), 60, hard.id());

        CalendarBlock done = service.setCompletion(f.user, b.id(), true).block();

        double rmr = StudyEnergy.restingMetabolicRate(70, 175, 21, BiologicalSex.MALE);
        assertThat(done.metValue()).isEqualTo(StudyEnergy.MET_CLASS);
        assertThat(done.caloriesBurned()).isCloseTo(StudyEnergy.blockCalories(rmr, 3600, 1.8), within(1e-9));
        // 60 min × 1,8 (asignatura difícil) = 108 min equivalentes: C = 1 - e^(-108/τ), τ = 240/ln 5.
        assertThat(done.cognitiveLoad()).isCloseTo(1 - Math.exp(-108 / (240 / Math.log(5))), within(1e-9));
        assertThat(done.attendanceRegisteredAt()).isEqualTo(PlannerFakes.END_OF_WEEK.instant());

        StudyBlockCompletionChanged event = (StudyBlockCompletionChanged) f.events.get(0);
        assertThat(event.activityType()).isEqualTo("clase");
        assertThat(event.subjectId()).isEqualTo(hard.id());
    }

    @Test
    void withoutProfileCaloriesAreNullAndRestBlocksGiveNoExperience() {
        CalendarBlock study = block(ActivityType.STUDY, at(0, 16, 0), 30, null);
        CalendarBlock done = service.setCompletion(f.user, study.id(), true).block();
        assertThat(done.caloriesBurned()).isNull();
        assertThat(done.metValue()).isEqualTo(StudyEnergy.MET_STUDY);
        assertThat(done.cognitiveLoad()).isCloseTo(1 - Math.exp(-30 / (240 / Math.log(5))), within(1e-9));

        CalendarBlock sleep = block(ActivityType.SLEEP, at(0, 23, 0), 480, null);
        SetBlockCompletionUseCase.Result result = service.setCompletion(f.user, sleep.id(), true);
        assertThat(result.xpDelta()).isZero();
        assertThat(result.block().metValue()).isNull();
    }

    @Test
    void completingRefreshesTheWeeklyLoad() {
        CalendarBlock b = block(ActivityType.STUDY, at(0, 16, 0), 120, null);
        service.setCompletion(f.user, b.id(), true);
        assertThat(f.loads.findByUserAndWeek(f.user, PlannerFakes.MONDAY)).hasValueSatisfying(l -> {
            assertThat(l.plannedHours()).isEqualTo(2);
            assertThat(l.actualHours()).isEqualTo(2);
        });
    }

    @Test
    void anotherUsersBlockIsNotFound() {
        CalendarBlock b = block(ActivityType.STUDY, at(0, 16, 0), 60, null);
        assertThatThrownBy(() -> service.setCompletion(f.otherUser, b.id(), true))
                .extracting("code").isEqualTo("BLOCK_NOT_FOUND");
    }

    @Test
    void aBlockCannotBeCompletedBeforeItStartsButAMissedOneCan() {
        BlockCompletionService early = new BlockCompletionService(f.blocks, f.directory, f.directory, f.xp, f.xp,
                f.publisher, f.weeklyLoadService(), PlannerFakes.ZONE, PlannerFakes.CLOCK);
        CalendarBlock future = block(ActivityType.STUDY, at(0, 16, 0), 60, null);
        assertThatThrownBy(() -> early.setCompletion(f.user, future.id(), true))
                .extracting("code").isEqualTo("BLOCK_IN_FUTURE");

        CalendarBlock missed = block(ActivityType.STUDY, at(0, 5, 0), 60, null);
        assertThat(missed.timeStatus(PlannerFakes.NOW)).isEqualTo(ItemTimeStatus.MISSED);
        assertThat(early.setCompletion(f.user, missed.id(), true).block().timeStatus(PlannerFakes.NOW))
                .isEqualTo(ItemTimeStatus.DONE);
    }
}
