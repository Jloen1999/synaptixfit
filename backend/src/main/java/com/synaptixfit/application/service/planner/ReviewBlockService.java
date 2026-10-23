package com.synaptixfit.application.service.planner;

import com.synaptixfit.application.port.input.planner.ScheduleReviewBlockUseCase;
import com.synaptixfit.domain.model.planner.ActivityType;
import com.synaptixfit.domain.model.planner.CalendarBlock;
import com.synaptixfit.domain.model.planner.PlannerZone;
import com.synaptixfit.domain.model.planner.Priority;
import com.synaptixfit.domain.model.planner.ScheduleConflicts;
import com.synaptixfit.domain.model.planner.TimeRange;
import com.synaptixfit.domain.port.output.planner.CalendarBlockRepositoryPort;
import com.synaptixfit.domain.port.output.planner.SubjectDirectoryPort;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Stream;

/**
 * Bloques de repaso espaciado generados por el módulo académico. Hay como mucho un bloque de repaso
 * pendiente por material: si ya existe, se mueve a la nueva fecha SM-2 en lugar de crear otro.
 *
 * <p>Regla de colocación: a la hora de vencimiento (redondeada a la media hora siguiente, nunca en el
 * pasado y no antes de las 08:00); si choca, primer hueco libre de 30 minutos de ese mismo día; si el
 * día está lleno, se crea igualmente a la hora prevista marcado con conflicto.
 */
public class ReviewBlockService implements ScheduleReviewBlockUseCase {

    static final int REVIEW_MINUTES = 30;
    static final LocalTime EARLIEST = LocalTime.of(8, 0);

    private final CalendarBlockRepositoryPort blocks;
    private final SubjectDirectoryPort subjects;
    private final PlannerZone zone;
    private final Clock clock;
    private final ConflictFlagger conflicts;

    public ReviewBlockService(CalendarBlockRepositoryPort blocks, SubjectDirectoryPort subjects, PlannerZone zone,
                              Clock clock) {
        this.blocks = blocks;
        this.subjects = subjects;
        this.zone = zone;
        this.clock = clock;
        this.conflicts = new ConflictFlagger(blocks);
    }

    @Override
    public Optional<CalendarBlock> scheduleReview(Command command) {
        Instant now = clock.instant();
        if (command.studyMaterialId() == null || command.dueAt() == null) {
            return Optional.empty();
        }
        Optional<CalendarBlock> pending = blocks.findPendingReviews(command.userId(), command.studyMaterialId())
                .stream().filter(b -> !b.isLocked()).findFirst();
        Instant desired = command.dueAt().isBefore(now) ? now : command.dueAt();
        LocalDate day = zone.localDate(desired);
        Instant earliest = zone.at(day, EARLIEST);
        if (desired.isBefore(earliest)) {
            desired = earliest;
        }
        TimeRange preferred = TimeRange.ofMinutes(ScheduleConflicts.alignToHalfHour(desired), REVIEW_MINUTES);
        Instant endOfDay = zone.startOfDay(day.plusDays(1));
        List<CalendarBlock> busy = blocks.findOverlapping(command.userId(), zone.startOfDay(day), endOfDay, null)
                .stream().filter(b -> pending.isEmpty() || !b.id().equals(pending.get().id())).toList();
        TimeRange range = ScheduleConflicts.firstFreeSlot(REVIEW_MINUTES, preferred.start(), endOfDay, busy)
                .orElse(preferred);
        if (pending.isPresent()) {
            return Optional.of(move(command.userId(), pending.get(), range, now));
        }
        // Una asignatura ajena o borrada no debe tumbar la transacción del repaso: se omite el vínculo.
        UUID subjectId = command.subjectId() != null && subjects.findOwned(command.userId(), command.subjectId()).isPresent()
                ? command.subjectId() : null;
        String title = command.title() == null || command.title().isBlank() ? "Repaso" : command.title();
        CalendarBlock block = CalendarBlock.builder()
                .id(UUID.randomUUID())
                .userId(command.userId())
                .range(range)
                .dayOfWeek(zone.dayOfWeek(range.start()))
                .type(ActivityType.REVIEW)
                .details(new CalendarBlock.Details(subjectId,
                        title.length() > CalendarBlock.TOPICS_MAX ? title.substring(0, CalendarBlock.TOPICS_MAX) : title,
                        null, Priority.MEDIUM, false, null, null, null, null, null, null, null))
                .studyMaterialId(command.studyMaterialId())
                .createdAt(now)
                .build();
        CalendarBlock saved = blocks.save(block);
        conflicts.refresh(command.userId(), List.of(saved), conflicts.neighboursOf(saved));
        return Optional.of(saved);
    }

    /**
     * El bloque pendiente sigue a la fecha SM-2: antes se dejaba en su fecha antigua y la nueva fecha
     * se perdía. Se mueve al hueco calculado y se recalculan los conflictos de ambos sitios.
     */
    private CalendarBlock move(UUID userId, CalendarBlock block, TimeRange range, Instant now) {
        List<CalendarBlock> oldNeighbours = conflicts.neighboursOf(block);
        block.moveTo(range, zone.dayOfWeek(range.start()), now);
        CalendarBlock saved = blocks.save(block);
        conflicts.refresh(userId, List.of(saved),
                Stream.concat(oldNeighbours.stream(), conflicts.neighboursOf(saved).stream()).toList());
        return saved;
    }
}
