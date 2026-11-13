package com.synaptixfit.application.service.planner;

import com.synaptixfit.application.port.input.planner.BlockChange;
import com.synaptixfit.application.port.input.planner.BlockDetailsInput;
import com.synaptixfit.application.port.input.planner.CreateCalendarBlockUseCase;
import com.synaptixfit.application.port.input.planner.RescheduleCalendarBlockUseCase;
import com.synaptixfit.application.port.input.planner.UpdateCalendarBlockUseCase;
import com.synaptixfit.domain.event.planner.StudyBlockCompletionChanged;
import com.synaptixfit.domain.exception.DomainException;
import com.synaptixfit.domain.model.planner.ActivityType;
import com.synaptixfit.domain.model.planner.CalendarBlock;
import com.synaptixfit.domain.model.planner.Deadline;
import com.synaptixfit.domain.model.planner.DeadlineType;
import com.synaptixfit.domain.model.planner.PlannerZone;
import com.synaptixfit.domain.model.planner.RoutineRef;
import com.synaptixfit.domain.model.planner.SubjectRef;
import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import static com.synaptixfit.application.service.planner.PlannerFakes.at;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class CalendarBlockServiceTest {

    private PlannerFakes f;
    private CalendarBlockService service;
    private BlockCompletionService completion;

    @BeforeEach
    void setUp() {
        f = new PlannerFakes();
        WeeklyLoadService loads = f.weeklyLoadService();
        service = new CalendarBlockService(f.blocks, f.deadlines, f.directory, f.directory, f.directory, f.xp,
                f.publisher, loads, PlannerFakes.ZONE, PlannerFakes.CLOCK, f.studyPlanService());
        completion = new BlockCompletionService(f.blocks, f.directory, f.directory, f.xp, f.xp, f.publisher, loads,
                PlannerFakes.ZONE, PlannerFakes.END_OF_WEEK);
    }

    private static BlockDetailsInput details(ActivityType type) {
        return new BlockDetailsInput(type, null, "Tema", null, null, false, null, null, null, null, null, null,
                null, null, null);
    }

    private BlockChange create(Instant start, Instant end, ActivityType type) {
        return service.createBlock(new CreateCalendarBlockUseCase.Command(f.user, start, end, false, details(type)));
    }

    @Test
    void planningTheWeekGivesItsExperienceAloneOnceAndDeletingEventsDoesNotTakeItBack() {
        create(at(1, 10, 0), at(1, 11, 0), ActivityType.STUDY);
        CalendarBlock second = create(at(2, 10, 0), at(2, 11, 0), ActivityType.SPORT).block();
        assertThat(f.xp.of(f.user)).isZero();

        CalendarBlock third = create(at(3, 10, 0), at(3, 11, 0), ActivityType.PERSONAL).block();
        assertThat(f.xp.of(f.user)).isEqualTo(115);

        // Ni se da dos veces al seguir añadiendo, ni se pierde al borrar y volver a crear.
        create(at(4, 10, 0), at(4, 11, 0), ActivityType.STUDY);
        service.deleteBlock(f.user, second.id());
        service.deleteBlock(f.user, third.id());
        create(at(5, 10, 0), at(5, 11, 0), ActivityType.STUDY);
        create(at(6, 10, 0), at(6, 11, 0), ActivityType.STUDY);
        assertThat(f.xp.of(f.user)).isEqualTo(115);
        assertThat(f.plans.store).hasSize(1);
    }

    @Test
    void aRepeatedEventCountsForTheNextWeekToo() {
        service.createBlock(new CreateCalendarBlockUseCase.Command(f.user, at(1, 10, 0), at(1, 11, 0), false,
                details(ActivityType.STUDY), 3));
        create(at(2, 10, 0), at(2, 11, 0), ActivityType.STUDY);
        create(at(3, 10, 0), at(3, 11, 0), ActivityType.STUDY);
        create(at(9, 10, 0), at(9, 11, 0), ActivityType.STUDY);
        create(at(10, 10, 0), at(10, 11, 0), ActivityType.STUDY);

        // Esta semana (3 eventos) y la siguiente (copia + 2); la copia de dentro de dos semanas, no.
        assertThat(f.xp.of(f.user)).isEqualTo(230);
        assertThat(f.plans.store).hasSize(2);
    }

    @Test
    void createsBlockWithDayOfWeekInPlannerZone() {
        // Martes 00:30 en Madrid es lunes 22:30 UTC: el día de la semana sale de la zona del planificador.
        CalendarBlock block = create(at(1, 0, 30), at(1, 1, 30), ActivityType.STUDY).block();
        assertThat(block.dayOfWeek()).isEqualTo(2);
        assertThat(block.hasConflict()).isFalse();
        assertThat(f.blocks.store).containsKey(block.id());
    }

    @Test
    void challengeBlocksStayWithinThePeriodAndTheTaskMustBelongToTheChallenge() {
        UUID challenge = UUID.randomUUID();
        UUID other = UUID.randomUUID();
        UUID task = UUID.randomUUID();
        f.directory.challenges.computeIfAbsent(f.user, k -> new java.util.HashSet<>()).addAll(List.of(challenge, other, task));
        f.directory.challengePeriods.put(challenge, new com.synaptixfit.domain.model.planner.ChallengeRef(challenge,
                at(1, 0, 0), at(3, 23, 0)));
        f.directory.milestoneChallenge.put(task, challenge);

        // La tarea indica su reto aunque no se envíe, y el bloque avisa a Retos para recalcular la tarea.
        CalendarBlock block = service.createBlock(new CreateCalendarBlockUseCase.Command(f.user, at(2, 10, 0),
                at(2, 11, 0), false, new BlockDetailsInput(ActivityType.STUDY, null, null, null, null, false, null,
                null, null, null, null, task, null, null, null))).block();
        assertThat(block.details().challengeId()).isEqualTo(challenge);
        assertThat(f.events).anyMatch(e -> e instanceof com.synaptixfit.domain.event.planner.StudyBlockAssignmentChanged);

        assertThatThrownBy(() -> service.createBlock(new CreateCalendarBlockUseCase.Command(f.user, at(5, 10, 0),
                at(5, 11, 0), false, new BlockDetailsInput(ActivityType.STUDY, null, null, null, null, false, null,
                null, null, null, challenge, task, null, null, null))))
                .extracting("code").isEqualTo("BLOCK_OUTSIDE_CHALLENGE_PERIOD");
        assertThatThrownBy(() -> service.createBlock(new CreateCalendarBlockUseCase.Command(f.user, at(2, 12, 0),
                at(2, 13, 0), false, new BlockDetailsInput(ActivityType.STUDY, null, null, null, null, false, null,
                null, null, null, other, task, null, null, null))))
                .extracting("code").isEqualTo("PLANNER_CHALLENGE_NOT_FOUND");
    }

    @Test
    void rejectsBlocksInThePast() {
        assertThatThrownBy(() -> create(PlannerFakes.NOW.minusSeconds(60), PlannerFakes.NOW.plusSeconds(3600),
                ActivityType.STUDY))
                .isInstanceOf(DomainException.class)
                .extracting("code").isEqualTo("BLOCK_IN_PAST");
    }

    @Test
    void rejectsBlocksShorterThan30Minutes() {
        assertThatThrownBy(() -> create(at(1, 10, 0), at(1, 10, 20), ActivityType.STUDY))
                .extracting("code").isEqualTo("BLOCK_INVALID_TIME_RANGE");
    }

    @Test
    void overlappingBlocksAreSavedAndBothFlaggedAsConflict() {
        CalendarBlock first = create(at(1, 10, 0), at(1, 12, 0), ActivityType.STUDY).block();
        BlockChange second = create(at(1, 11, 0), at(1, 13, 0), ActivityType.SPORT);

        assertThat(second.conflicts()).extracting(CalendarBlock::id).containsExactly(first.id());
        assertThat(f.blocks.store.get(second.block().id()).hasConflict()).isTrue();
        assertThat(f.blocks.store.get(first.id()).hasConflict()).isTrue();

        // Al moverlo fuera, ambos dejan de estar en conflicto.
        service.reschedule(new RescheduleCalendarBlockUseCase.Command(f.user, second.block().id(), at(1, 14, 0), null));
        assertThat(f.blocks.store.get(second.block().id()).hasConflict()).isFalse();
        assertThat(f.blocks.store.get(first.id()).hasConflict()).isFalse();
    }

    @Test
    void contiguousBlocksDoNotConflict() {
        create(at(1, 10, 0), at(1, 11, 0), ActivityType.STUDY);
        assertThat(create(at(1, 11, 0), at(1, 12, 0), ActivityType.STUDY).conflicts()).isEmpty();
    }

    @Test
    void examBlockCreatesLinkedDeadlineDueAtTheBlockStart() {
        CalendarBlock exam = service.createBlock(new CreateCalendarBlockUseCase.Command(f.user, at(2, 9, 0),
                at(2, 11, 0), false, new BlockDetailsInput(ActivityType.EXAM, null, null, "Aula 1", null, false, null,
                null, null, null, null, null, null, "Parcial de Álgebra", null))).block();

        Deadline deadline = f.deadlines.store.get(exam.details().deadlineId());
        assertThat(deadline.type()).isEqualTo(DeadlineType.EXAM);
        assertThat(deadline.title()).isEqualTo("Parcial de Álgebra");
        assertThat(deadline.dueAt()).isEqualTo(at(2, 9, 0));
    }

    @Test
    void deliveryBlockDeadlineIsDueAtTheBlockEnd() {
        CalendarBlock delivery = create(at(2, 9, 0), at(2, 11, 0), ActivityType.DELIVERY).block();
        assertThat(f.deadlines.store.get(delivery.details().deadlineId()).dueAt()).isEqualTo(at(2, 11, 0));
    }

    @Test
    void movingAnExamBlockMovesItsDeadline() {
        CalendarBlock exam = create(at(2, 9, 0), at(2, 11, 0), ActivityType.EXAM).block();
        service.reschedule(new RescheduleCalendarBlockUseCase.Command(f.user, exam.id(), at(3, 12, 0), null));
        assertThat(f.deadlines.store.get(exam.details().deadlineId()).dueAt()).isEqualTo(at(3, 12, 0));
    }

    @Test
    void foreignSubjectIsNotFound() {
        SubjectRef foreign = f.directory.addSubject(f.otherUser, "Física", "FIS", 3);
        BlockDetailsInput input = new BlockDetailsInput(ActivityType.STUDY, foreign.id(), null, null, null, false, null,
                null, null, null, null, null, null, null, null);
        assertThatThrownBy(() -> service.createBlock(new CreateCalendarBlockUseCase.Command(f.user, at(1, 10, 0),
                at(1, 11, 0), false, input)))
                .extracting("code").isEqualTo("PLANNER_SUBJECT_NOT_FOUND");
    }

    @Test
    void routineDayMustBelongToTheRoutine() {
        UUID weekId = UUID.randomUUID();
        RoutineRef routine = new RoutineRef(UUID.randomUUID(), "Torso", "Fuerza", 1, 5,
                List.of(new RoutineRef.Day(UUID.randomUUID(), weekId, 1, 1, "Día 1")));
        f.directory.routines.put(f.user, Map.of(routine.id(), routine));
        BlockDetailsInput bad = new BlockDetailsInput(ActivityType.SPORT, null, null, null, null, false, null,
                routine.id(), null, UUID.randomUUID(), null, null, null, null, null);
        assertThatThrownBy(() -> service.createBlock(new CreateCalendarBlockUseCase.Command(f.user, at(1, 18, 0),
                at(1, 19, 0), false, bad)))
                .extracting("code").isEqualTo("PLANNER_ROUTINE_NOT_FOUND");

        BlockDetailsInput ok = new BlockDetailsInput(ActivityType.SPORT, null, null, null, null, false, null,
                routine.id(), null, routine.days().get(0).id(), null, null, null, null, null);
        CalendarBlock block = service.createBlock(new CreateCalendarBlockUseCase.Command(f.user, at(1, 18, 0),
                at(1, 19, 0), false, ok)).block();
        assertThat(block.details().routineWeekId()).isEqualTo(weekId);
    }

    @Test
    void anotherUsersBlockIsNotFound() {
        CalendarBlock block = create(at(1, 10, 0), at(1, 11, 0), ActivityType.STUDY).block();
        assertThatThrownBy(() -> service.getBlock(f.otherUser, block.id()))
                .extracting("code").isEqualTo("BLOCK_NOT_FOUND");
        assertThatThrownBy(() -> service.deleteBlock(f.otherUser, block.id()))
                .extracting("code").isEqualTo("BLOCK_NOT_FOUND");
    }

    @Test
    void moveKeepsDurationAndResizeChangesEnd() {
        CalendarBlock block = create(at(1, 10, 0), at(1, 11, 30), ActivityType.STUDY).block();
        CalendarBlock moved = service.reschedule(
                new RescheduleCalendarBlockUseCase.Command(f.user, block.id(), at(3, 16, 0), null)).block();
        assertThat(moved.end()).isEqualTo(at(3, 17, 30));
        assertThat(moved.dayOfWeek()).isEqualTo(4);

        CalendarBlock resized = service.reschedule(
                new RescheduleCalendarBlockUseCase.Command(f.user, block.id(), null, at(3, 18, 0))).block();
        assertThat(resized.range().minutes()).isEqualTo(120);
    }

    @Test
    void cannotMoveIntoThePastNorMoveLockedOrCompletedBlocks() {
        CalendarBlock block = create(at(1, 10, 0), at(1, 11, 0), ActivityType.STUDY).block();
        assertThatThrownBy(() -> service.reschedule(new RescheduleCalendarBlockUseCase.Command(f.user, block.id(),
                PlannerFakes.NOW.minus(Duration.ofHours(2)), null)))
                .extracting("code").isEqualTo("BLOCK_IN_PAST");

        CalendarBlock fixed = service.createBlock(new CreateCalendarBlockUseCase.Command(f.user, at(2, 10, 0),
                at(2, 11, 0), true, details(ActivityType.CLASS))).block();
        assertThatThrownBy(() -> service.reschedule(new RescheduleCalendarBlockUseCase.Command(f.user, fixed.id(),
                at(4, 10, 0), null)))
                .extracting("code").isEqualTo("BLOCK_LOCKED");

        completion.setCompletion(f.user, block.id(), true);
        assertThatThrownBy(() -> service.reschedule(new RescheduleCalendarBlockUseCase.Command(f.user, block.id(),
                null, at(1, 13, 0))))
                .extracting("code").isEqualTo("BLOCK_COMPLETED_LOCKED");
        assertThatThrownBy(() -> service.updateBlock(new UpdateCalendarBlockUseCase.Command(f.user, block.id(),
                details(ActivityType.SLEEP))))
                .extracting("code").isEqualTo("BLOCK_COMPLETED_LOCKED");
    }

    @Test
    void deletingACompletedBlockRevokesItsExperienceAndPublishesUncompletion() {
        CalendarBlock block = create(at(1, 10, 0), at(1, 11, 30), ActivityType.STUDY).block();
        completion.setCompletion(f.user, block.id(), true);
        assertThat(f.xp.of(f.user)).isEqualTo(30);
        f.events.clear();

        service.deleteBlock(f.user, block.id());

        assertThat(f.xp.of(f.user)).isZero();
        assertThat(f.blocks.store).doesNotContainKey(block.id());
        assertThat(f.events).singleElement().isInstanceOfSatisfying(StudyBlockCompletionChanged.class,
                e -> assertThat(e.completed()).isFalse());
    }

    @Test
    void conflictsOfTheWeekArePairs() {
        create(at(1, 10, 0), at(1, 12, 0), ActivityType.STUDY);
        create(at(1, 11, 0), at(1, 13, 0), ActivityType.STUDY);
        create(at(2, 11, 0), at(2, 13, 0), ActivityType.STUDY);
        assertThat(service.getConflicts(f.user, PlannerFakes.MONDAY.plusDays(3))).hasSize(1);
    }

    @Test
    void rangeQueriesAreBounded() {
        assertThatThrownBy(() -> service.getBlocks(f.user, at(0, 0, 0), at(200, 0, 0), null))
                .extracting("code").isEqualTo("PLANNER_RANGE_TOO_LARGE");
    }

    @Test
    void repeatsTheBlockEveryWeekAtTheSameLocalTime() {
        // El 25 de octubre cambia la hora en Madrid: las copias siguen a las 18:00 locales.
        BlockChange change = service.createBlock(new CreateCalendarBlockUseCase.Command(f.user, at(1, 18, 0),
                at(1, 19, 0), false, details(ActivityType.STUDY), 3));

        assertThat(change.weeklyCopies()).isEqualTo(3);
        assertThat(f.blocks.store).hasSize(4);
        PlannerZone zone = PlannerFakes.ZONE;
        assertThat(f.blocks.store.values()).extracting(b -> zone.localTime(b.range().start()).getHour())
                .containsOnly(18);
        assertThat(f.blocks.store.values()).extracting(b -> zone.localDate(b.range().start()))
                .containsExactlyInAnyOrder(zone.localDate(at(1, 18, 0)), zone.localDate(at(1, 18, 0)).plusWeeks(1),
                        zone.localDate(at(1, 18, 0)).plusWeeks(2), zone.localDate(at(1, 18, 0)).plusWeeks(3));
    }

    @Test
    void examsAreNotRepeatedAndTheRepeatCountIsCapped() {
        assertThat(service.createBlock(new CreateCalendarBlockUseCase.Command(f.user, at(2, 9, 0), at(2, 11, 0),
                false, details(ActivityType.EXAM), 4)).weeklyCopies()).isZero();
        assertThat(service.createBlock(new CreateCalendarBlockUseCase.Command(f.user, at(3, 9, 0), at(3, 10, 0),
                false, details(ActivityType.STUDY), 99)).weeklyCopies()).isEqualTo(CalendarBlock.MAX_WEEKLY_REPEATS);
    }

    @Test
    void reschedulingToTheNextFreeSlotSkipsBusyTimeAndNight() {
        // Lunes: estudio 10:00-12:00 y deporte 12:00-13:00; el bloque de 60 min va a las 13:00.
        create(at(0, 10, 0), at(0, 12, 0), ActivityType.STUDY);
        create(at(0, 12, 0), at(0, 13, 0), ActivityType.SPORT);
        CalendarBlock toMove = create(at(2, 18, 0), at(2, 19, 0), ActivityType.STUDY).block();

        BlockChange moved = service.rescheduleToNextFreeSlot(f.user, toMove.id());

        assertThat(moved.block().start()).isEqualTo(at(0, 13, 0));
        assertThat(moved.block().end()).isEqualTo(at(0, 14, 0));
    }

    @Test
    void withdrawingRoutineBlocksKeepsHistoryUnlessTheDayIsGone() {
        UUID routineId = UUID.randomUUID();
        UUID dayId = UUID.randomUUID();
        java.util.function.BiFunction<Instant, Boolean, CalendarBlock> block = (start, done) -> {
            CalendarBlock b = CalendarBlock.builder().id(UUID.randomUUID()).userId(f.user)
                    .range(com.synaptixfit.domain.model.planner.TimeRange.ofMinutes(start, 60)).type(ActivityType.SPORT)
                    .details(new CalendarBlock.Details(null, "Semana 1 · Empuje", null,
                            com.synaptixfit.domain.model.planner.Priority.MEDIUM, false, null, routineId,
                            UUID.randomUUID(), dayId, null, null, null))
                    .build();
            if (done) {
                b.complete(start.plusSeconds(3600), null, null, null);
            }
            return f.blocks.save(b);
        };
        CalendarBlock past = block.apply(PlannerFakes.NOW.minus(Duration.ofDays(2)), false);
        CalendarBlock done = block.apply(PlannerFakes.NOW.minus(Duration.ofDays(1)), true);
        CalendarBlock future = block.apply(PlannerFakes.NOW.plus(Duration.ofDays(1)), false);

        // Rutina pausada: solo los futuros pendientes.
        service.withdraw(new com.synaptixfit.application.port.input.planner.WithdrawRoutineBlocksUseCase.Command(
                f.user, routineId, java.util.Set.of(), true));
        assertThat(f.blocks.store.keySet()).containsExactlyInAnyOrder(past.id(), done.id());

        // Día quitado de la rutina: todos sus bloques, también el completado.
        service.withdraw(new com.synaptixfit.application.port.input.planner.WithdrawRoutineBlocksUseCase.Command(
                f.user, routineId, java.util.Set.of(dayId), false, true));
        assertThat(f.blocks.store).isEmpty();
        assertThat(future).isNotNull();
    }
}
