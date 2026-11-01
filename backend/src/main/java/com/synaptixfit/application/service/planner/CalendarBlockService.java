package com.synaptixfit.application.service.planner;

import com.synaptixfit.application.port.input.gamification.RevokeExperienceUseCase;
import com.synaptixfit.application.port.input.planner.BlockChange;
import com.synaptixfit.application.port.input.planner.BlockDetailsInput;
import com.synaptixfit.application.port.input.planner.CreateCalendarBlockUseCase;
import com.synaptixfit.application.port.input.planner.DeleteCalendarBlockUseCase;
import com.synaptixfit.application.port.input.planner.DeleteSubjectBlocksUseCase;
import com.synaptixfit.application.port.input.planner.GetCalendarBlockUseCase;
import com.synaptixfit.application.port.input.planner.GetCalendarBlocksUseCase;
import com.synaptixfit.application.port.input.planner.GetScheduleConflictsUseCase;
import com.synaptixfit.application.port.input.planner.RescheduleBlockToNextFreeSlotUseCase;
import com.synaptixfit.application.port.input.planner.RescheduleCalendarBlockUseCase;
import com.synaptixfit.application.port.input.planner.UpdateCalendarBlockUseCase;
import com.synaptixfit.application.port.input.planner.WithdrawRoutineBlocksUseCase;
import com.synaptixfit.domain.event.planner.SportBlockCompletionChanged;
import com.synaptixfit.domain.event.planner.StudyBlockAssignmentChanged;
import com.synaptixfit.domain.event.planner.StudyBlockCompletionChanged;
import com.synaptixfit.domain.exception.FieldValidationException;
import com.synaptixfit.domain.exception.planner.BlockNoFreeSlotException;
import com.synaptixfit.domain.exception.planner.CalendarBlockNotFoundException;
import com.synaptixfit.domain.model.planner.ActivityType;
import com.synaptixfit.domain.model.planner.CalendarBlock;
import com.synaptixfit.domain.model.planner.Deadline;
import com.synaptixfit.domain.model.planner.DeadlineType;
import com.synaptixfit.domain.model.planner.PlannerZone;
import com.synaptixfit.domain.model.planner.ScheduleConflicts;
import com.synaptixfit.domain.model.planner.TimeRange;
import com.synaptixfit.domain.port.output.event.DomainEventPublisherPort;
import com.synaptixfit.domain.port.output.planner.CalendarBlockRepositoryPort;
import com.synaptixfit.domain.port.output.planner.ChallengeDirectoryPort;
import com.synaptixfit.domain.port.output.planner.DeadlineRepositoryPort;
import com.synaptixfit.domain.port.output.planner.RoutineDirectoryPort;
import com.synaptixfit.domain.port.output.planner.SubjectDirectoryPort;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.util.HashSet;
import java.util.List;
import java.util.Objects;
import java.util.Set;
import java.util.UUID;

/**
 * Bloques del calendario: consulta, alta, edición, cambio de horario, borrado y conflictos. También
 * borra los bloques que dejan de tener sentido por otros módulos (asignatura eliminada, días de rutina
 * saltados o quitados, rutina que deja de estar en curso).
 */
public class CalendarBlockService implements GetCalendarBlocksUseCase, GetCalendarBlockUseCase,
        RescheduleBlockToNextFreeSlotUseCase,
        CreateCalendarBlockUseCase, UpdateCalendarBlockUseCase, RescheduleCalendarBlockUseCase,
        DeleteCalendarBlockUseCase, GetScheduleConflictsUseCase, DeleteSubjectBlocksUseCase,
        WithdrawRoutineBlocksUseCase {

    private final CalendarBlockRepositoryPort blocks;
    private final DeadlineRepositoryPort deadlines;
    private final RevokeExperienceUseCase revoke;
    private final DomainEventPublisherPort events;
    private final WeeklyLoadService weeklyLoads;
    private final PlannerZone zone;
    private final Clock clock;
    private final BlockDetailsResolver resolver;
    private final ConflictFlagger conflicts;

    public CalendarBlockService(CalendarBlockRepositoryPort blocks, DeadlineRepositoryPort deadlines,
                                SubjectDirectoryPort subjects, RoutineDirectoryPort routines,
                                ChallengeDirectoryPort challenges, RevokeExperienceUseCase revoke,
                                DomainEventPublisherPort events, WeeklyLoadService weeklyLoads,
                                PlannerZone zone, Clock clock) {
        this.blocks = blocks;
        this.deadlines = deadlines;
        this.revoke = revoke;
        this.events = events;
        this.weeklyLoads = weeklyLoads;
        this.zone = zone;
        this.clock = clock;
        this.resolver = new BlockDetailsResolver(subjects, routines, challenges, deadlines, zone);
        this.conflicts = new ConflictFlagger(blocks);
    }

    @Override
    public List<CalendarBlock> getBlocks(UUID userId, Instant from, Instant to, UUID subjectId) {
        Ranges.check(from, to, Ranges.MAX_QUERY_DAYS);
        return blocks.findOverlapping(userId, from, to, subjectId);
    }

    @Override
    public CalendarBlock getBlock(UUID userId, UUID blockId) {
        return owned(userId, blockId);
    }

    @Override
    public BlockChange createBlock(CreateCalendarBlockUseCase.Command command) {
        Instant now = clock.instant();
        TimeRange range = new TimeRange(command.start(), command.end());
        BlockDetailsInput input = command.details();
        ActivityType type = input.type() == null ? ActivityType.STUDY : input.type();
        CalendarBlock.Details details = resolver.resolve(command.userId(), input, range);
        CalendarBlock block = CalendarBlock.builder()
                .id(UUID.randomUUID())
                .userId(command.userId())
                .range(range)
                .dayOfWeek(zone.dayOfWeek(range.start()))
                .type(type)
                .details(details)
                .fixed(command.fixed())
                .createdAt(now)
                .build();
        block.requireNotInPast(now);
        if ((type == ActivityType.EXAM || type == ActivityType.DELIVERY) && details.deadlineId() == null) {
            Deadline deadline = deadlines.save(linkedDeadline(command.userId(), type, range, input, now));
            block.revise(type, withDeadline(details, deadline.id()));
            weeklyLoads.refresh(command.userId(), zone.localDate(deadline.dueAt()));
        }
        CalendarBlock saved = blocks.save(block);
        List<CalendarBlock> neighbours = conflicts.neighboursOf(saved);
        conflicts.refresh(command.userId(), List.of(saved), neighbours);
        int copies = type.canRepeatWeekly()
                ? Math.max(0, Math.min(command.repeatWeeks(), CalendarBlock.MAX_WEEKLY_REPEATS)) : 0;
        int made = 0;
        for (int week = 1; week <= copies; week++) {
            CalendarBlock next = weeklyCopy(saved, week, now);
            // Las copias de un bloque de reto se quedan dentro del periodo del reto.
            if (!resolver.fitsChallengePeriod(command.userId(), next.details().challengeId(), next.range())) {
                break;
            }
            CalendarBlock copy = blocks.save(next);
            conflicts.refresh(command.userId(), List.of(copy), conflicts.neighboursOf(copy));
            made++;
        }
        publishAssignment(command.userId(), null, saved.details().milestoneId());
        return new BlockChange(saved, neighbours, made);
    }

    /** Copia de {@code original} {@code week} semanas después, a la misma hora local. */
    private CalendarBlock weeklyCopy(CalendarBlock original, int week, Instant now) {
        TimeRange range = new TimeRange(zone.plusWeeks(original.range().start(), week),
                zone.plusWeeks(original.range().end(), week));
        return original.weeklyCopy(UUID.randomUUID(), range, zone.dayOfWeek(range.start()), now);
    }

    @Override
    public BlockChange rescheduleToNextFreeSlot(UUID userId, UUID blockId) {
        CalendarBlock block = owned(userId, blockId);
        Instant now = clock.instant();
        long minutes = block.range().minutes();
        Instant horizon = zone.startOfDay(zone.today(now).plusDays(ScheduleConflicts.RESCHEDULE_DAYS_AHEAD + 1L));
        List<CalendarBlock> busy = blocks.findOverlapping(userId, now, horizon, null).stream()
                .filter(b -> !b.id().equals(blockId))
                .toList();
        TimeRange slot = ScheduleConflicts.nextFreeSlot(minutes, now, zone, busy)
                .orElseThrow(BlockNoFreeSlotException::new);
        return reschedule(new RescheduleCalendarBlockUseCase.Command(userId, blockId, slot.start(), slot.end()));
    }

    /** Entrega/examen que acompaña a un bloque EXAM o DELIVERY: la hora indicada de un examen es su inicio. */
    private static Deadline linkedDeadline(UUID userId, ActivityType type, TimeRange range, BlockDetailsInput in,
                                           Instant now) {
        String title = firstNonBlank(in.deadlineTitle(), in.topics(), type == ActivityType.EXAM ? "Examen" : "Entrega");
        return Deadline.builder()
                .id(UUID.randomUUID())
                .userId(userId)
                .subjectId(in.subjectId())
                .title(title.length() > Deadline.TITLE_MAX ? title.substring(0, Deadline.TITLE_MAX) : title)
                .type(type == ActivityType.EXAM ? DeadlineType.EXAM : DeadlineType.ASSIGNMENT)
                .dueAt(type == ActivityType.EXAM ? range.start() : range.end())
                .difficulty(in.deadlineDifficulty())
                .createdAt(now)
                .updatedAt(now)
                .build();
    }

    @Override
    public CalendarBlock updateBlock(UpdateCalendarBlockUseCase.Command command) {
        CalendarBlock block = owned(command.userId(), command.blockId());
        ActivityType type = command.details().type() == null ? block.type() : command.details().type();
        UUID previousMilestone = block.details().milestoneId();
        block.revise(type, resolver.resolve(command.userId(), command.details(), block.range()));
        CalendarBlock saved = blocks.save(block);
        publishAssignment(command.userId(), previousMilestone, saved.details().milestoneId());
        return saved;
    }

    @Override
    public BlockChange reschedule(RescheduleCalendarBlockUseCase.Command command) {
        CalendarBlock block = owned(command.userId(), command.blockId());
        Instant now = clock.instant();
        List<CalendarBlock> formerNeighbours = conflicts.neighboursOf(block);
        LocalDate previousDay = zone.localDate(block.start());
        if (command.start() != null) {
            TimeRange target = command.end() == null
                    ? block.range().shiftTo(command.start())
                    : new TimeRange(command.start(), command.end());
            resolver.checkChallengePeriod(command.userId(), block.details().challengeId(), target);
            block.moveTo(target, zone.dayOfWeek(target.start()), now);
        } else if (command.end() != null) {
            block.resize(command.end(), now);
        } else {
            throw new FieldValidationException("start", "REQUIRED", "start or end is required");
        }
        CalendarBlock saved = blocks.save(block);
        followLinkedDeadline(saved, now);
        List<CalendarBlock> neighbours = conflicts.neighboursOf(saved);
        conflicts.refresh(command.userId(), List.of(saved),
                java.util.stream.Stream.concat(formerNeighbours.stream(), neighbours.stream()).toList());
        weeklyLoads.refresh(command.userId(), zone.localDate(saved.start()));
        if (!PlannerZone.mondayOf(previousDay).equals(PlannerZone.mondayOf(zone.localDate(saved.start())))) {
            weeklyLoads.refresh(command.userId(), previousDay);
        }
        return new BlockChange(saved, neighbours);
    }

    @Override
    public void deleteBlock(UUID userId, UUID blockId) {
        remove(owned(userId, blockId));
    }

    @Override
    public void deleteSubjectBlocks(UUID userId, UUID subjectId) {
        blocks.findBySubject(userId, subjectId).forEach(this::remove);
    }

    @Override
    public void withdraw(WithdrawRoutineBlocksUseCase.Command c) {
        Instant now = clock.instant();
        List<CalendarBlock> linked = c.dayIds().isEmpty()
                ? blocks.findByRoutine(c.userId(), c.routineId())
                : blocks.findByRoutineDays(c.userId(), c.dayIds());
        linked.stream()
                .filter(b -> c.includeCompleted() || !b.completed())
                .filter(b -> !c.onlyFuture() || b.start().isAfter(now))
                .forEach(this::remove);
    }

    /**
     * Avisa de que cambian los bloques de unas tareas de reto (alta, cambio de tarea o baja), para que su
     * progreso por bloques se recalcule. Sin tareas afectadas no publica nada.
     */
    private void publishAssignment(UUID userId, UUID before, UUID after) {
        Set<UUID> milestones = new HashSet<>();
        if (before != null) {
            milestones.add(before);
        }
        if (after != null) {
            milestones.add(after);
        }
        if (!milestones.isEmpty() && !(before != null && before.equals(after))) {
            events.publish(new StudyBlockAssignmentChanged(userId, milestones, clock.instant()));
        }
    }

    /** Borra el bloque restando su XP, avisa si estaba completado y recalcula conflictos y semana. */
    private void remove(CalendarBlock block) {
        UUID userId = block.userId();
        List<CalendarBlock> neighbours = conflicts.neighboursOf(block);
        if (block.xpAwarded()) {
            revoke.revoke(userId, block.experienceReward());
        }
        blocks.delete(block.id());
        conflicts.refresh(userId, List.of(), neighbours);
        if (!block.completed()) {
            // Completado ya avisa abajo; sin completar, la tarea pasa a tener un bloque menos.
            publishAssignment(userId, block.details().milestoneId(), null);
        }
        weeklyLoads.refresh(userId, zone.localDate(block.start()));
        if (block.completed()) {
            events.publish(new StudyBlockCompletionChanged(userId, block.id(), block.type().code(), block.subjectId(),
                    block.details().milestoneId(), block.start(), block.end(), false, clock.instant()));
            if (block.countsAsPhysicalActivity()) {
                // Indicadores retira su carga y recalcula el ACWR (no depende de la cascada de la BD).
                events.publish(new SportBlockCompletionChanged(userId, block.id(), zone.localDate(block.start()), null,
                        (int) block.range().minutes(), false, clock.instant()));
            }
        }
    }

    @Override
    public List<ScheduleConflicts.Pair> getConflicts(UUID userId, LocalDate weekStart) {
        Instant from = zone.weekStart(weekStart);
        Instant to = zone.weekEnd(weekStart);
        return ScheduleConflicts.pairs(blocks.findOverlapping(userId, from, to, null));
    }

    /** La fecha límite de la entrega/examen vinculados sigue al bloque cuando se mueve. */
    private void followLinkedDeadline(CalendarBlock block, Instant now) {
        boolean deadlineBlock = block.type() == ActivityType.EXAM || block.type() == ActivityType.DELIVERY;
        if (!deadlineBlock || block.details().deadlineId() == null) {
            return;
        }
        Instant dueAt = block.type() == ActivityType.EXAM ? block.start() : block.end();
        deadlines.findById(block.details().deadlineId())
                .filter(d -> d.userId().equals(block.userId()) && !d.dueAt().equals(dueAt))
                .ifPresent(d -> {
                    LocalDate previousWeek = zone.localDate(d.dueAt());
                    d.update(null, null, dueAt, null, null, null, false, now);
                    deadlines.save(d);
                    weeklyLoads.refresh(block.userId(), previousWeek);
                });
    }

    private CalendarBlock owned(UUID userId, UUID blockId) {
        return blocks.findById(blockId)
                .filter(b -> b.userId().equals(userId))
                .orElseThrow(() -> new CalendarBlockNotFoundException(blockId));
    }

    private static CalendarBlock.Details withDeadline(CalendarBlock.Details d, UUID deadlineId) {
        return new CalendarBlock.Details(d.subjectId(), d.topics(), d.location(), d.priority(), d.isPrivate(),
                d.classKind(), d.routineId(), d.routineWeekId(), d.routineDayId(), d.challengeId(), d.milestoneId(),
                deadlineId);
    }

    private static String firstNonBlank(String... values) {
        for (String v : values) {
            if (v != null && !v.isBlank()) {
                return v.strip();
            }
        }
        return Objects.requireNonNull(values[values.length - 1]);
    }
}
