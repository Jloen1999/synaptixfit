package com.synaptixfit.application.service.planner;

import com.synaptixfit.application.port.input.gamification.AwardExperienceUseCase;
import com.synaptixfit.application.port.input.gamification.RevokeExperienceUseCase;
import com.synaptixfit.application.port.input.planner.CreateDeadlineUseCase;
import com.synaptixfit.application.port.input.planner.CreateDeadlinesFromGuideUseCase;
import com.synaptixfit.application.port.input.planner.DeleteDeadlineUseCase;
import com.synaptixfit.application.port.input.planner.GetDeadlineUseCase;
import com.synaptixfit.application.port.input.planner.GetDeadlinesUseCase;
import com.synaptixfit.application.port.input.planner.SetDeadlineCompletionUseCase;
import com.synaptixfit.application.port.input.planner.SyncDeadlineFromChallengeUseCase;
import com.synaptixfit.application.port.input.planner.UpdateDeadlineUseCase;
import com.synaptixfit.domain.event.planner.DeadlineCompletionChanged;
import com.synaptixfit.domain.exception.planner.DeadlineNotFoundException;
import com.synaptixfit.domain.exception.planner.PlannerSubjectNotFoundException;
import com.synaptixfit.domain.model.planner.Deadline;
import com.synaptixfit.domain.model.planner.DeadlineType;
import com.synaptixfit.domain.model.planner.PlannerZone;
import com.synaptixfit.domain.model.planner.Priority;
import com.synaptixfit.domain.model.shared.PageResult;
import com.synaptixfit.domain.port.output.event.DomainEventPublisherPort;
import com.synaptixfit.domain.port.output.planner.DeadlineRepositoryPort;
import com.synaptixfit.domain.port.output.planner.SubjectDirectoryPort;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/** Entregas, exámenes y presentaciones: CRUD, consulta y completado con experiencia. */
public class DeadlineService implements CreateDeadlineUseCase, CreateDeadlinesFromGuideUseCase, UpdateDeadlineUseCase, DeleteDeadlineUseCase,
        GetDeadlineUseCase, GetDeadlinesUseCase, SetDeadlineCompletionUseCase, SyncDeadlineFromChallengeUseCase {

    private final DeadlineRepositoryPort deadlines;
    private final SubjectDirectoryPort subjects;
    private final AwardExperienceUseCase award;
    private final RevokeExperienceUseCase revoke;
    private final DomainEventPublisherPort events;
    private final WeeklyLoadService weeklyLoads;
    private final PlannerZone zone;
    private final Clock clock;

    public DeadlineService(DeadlineRepositoryPort deadlines, SubjectDirectoryPort subjects,
                           AwardExperienceUseCase award, RevokeExperienceUseCase revoke,
                           DomainEventPublisherPort events, WeeklyLoadService weeklyLoads, PlannerZone zone,
                           Clock clock) {
        this.deadlines = deadlines;
        this.subjects = subjects;
        this.award = award;
        this.revoke = revoke;
        this.events = events;
        this.weeklyLoads = weeklyLoads;
        this.zone = zone;
        this.clock = clock;
    }

    @Override
    public Deadline createDeadline(CreateDeadlineUseCase.Command command) {
        requireSubject(command.userId(), command.subjectId());
        Instant now = clock.instant();
        Deadline saved = deadlines.save(Deadline.builder()
                .id(UUID.randomUUID())
                .userId(command.userId())
                .subjectId(command.subjectId())
                .title(command.title())
                .type(command.type())
                .dueAt(command.dueAt())
                .difficulty(command.difficulty())
                .description(command.description())
                .createdAt(now)
                .updatedAt(now)
                .build());
        weeklyLoads.refresh(command.userId(), zone.localDate(saved.dueAt()));
        return saved;
    }

    @Override
    public int createFromGuide(CreateDeadlinesFromGuideUseCase.Command command) {
        requireSubject(command.userId(), command.subjectId());
        List<Deadline> existing = new ArrayList<>(deadlines.findAll(command.userId(),
                new DeadlineRepositoryPort.Query(null, null, command.subjectId(), false)));
        int created = 0;
        for (CreateDeadlinesFromGuideUseCase.Item item : command.items()) {
            LocalDate day = zone.localDate(item.dueAt());
            boolean duplicate = existing.stream().anyMatch(d -> d.title().equalsIgnoreCase(item.title().strip())
                    && zone.localDate(d.dueAt()).equals(day));
            if (duplicate) {
                continue;
            }
            // Un examen pesa más en la carga de la semana que una entrega o una presentación.
            Priority difficulty = item.type() == DeadlineType.EXAM ? Priority.HIGH : Priority.MEDIUM;
            existing.add(createDeadline(new CreateDeadlineUseCase.Command(command.userId(), item.title(), item.type(),
                    item.dueAt(), difficulty, item.description(), command.subjectId())));
            created++;
        }
        return created;
    }

    @Override
    public Deadline updateDeadline(UpdateDeadlineUseCase.Command command) {
        Deadline deadline = owned(command.userId(), command.deadlineId());
        if (!command.clearSubject()) {
            requireSubject(command.userId(), command.subjectId());
        }
        LocalDate previousDay = zone.localDate(deadline.dueAt());
        deadline.update(command.title(), command.type(), command.dueAt(), command.difficulty(), command.description(),
                command.subjectId(), command.clearSubject(), clock.instant());
        Deadline saved = deadlines.save(deadline);
        weeklyLoads.refresh(command.userId(), zone.localDate(saved.dueAt()));
        if (!PlannerZone.mondayOf(previousDay).equals(PlannerZone.mondayOf(zone.localDate(saved.dueAt())))) {
            weeklyLoads.refresh(command.userId(), previousDay);
        }
        return saved;
    }

    @Override
    public void deleteDeadline(UUID userId, UUID deadlineId) {
        Deadline deadline = owned(userId, deadlineId);
        if (deadline.xpAwarded()) {
            revoke.revoke(userId, Deadline.EXPERIENCE);
        }
        deadlines.delete(deadline.id());
        weeklyLoads.refresh(userId, zone.localDate(deadline.dueAt()));
        // Borrar una entrega completada equivale a descompletarla para los retos y tareas vinculados
        // (que se completaron con ella): así su XP y su estado no quedan colgados.
        if (deadline.completed()) {
            events.publish(new DeadlineCompletionChanged(userId, deadline.id(), false, clock.instant()));
        }
    }

    @Override
    public Deadline getDeadline(UUID userId, UUID deadlineId) {
        return owned(userId, deadlineId);
    }

    @Override
    public PageResult<Deadline> getDeadlines(Query query) {
        Instant from = query.from();
        boolean pendingOnly = false;
        if (query.upcomingOnly()) {
            Instant today = zone.startOfDay(zone.today(clock.instant()));
            from = from == null || from.isBefore(today) ? today : from;
            pendingOnly = true;
        }
        return deadlines.find(query.userId(),
                new DeadlineRepositoryPort.Query(from, query.to(), query.subjectId(), pendingOnly), query.page());
    }

    @Override
    public Result setCompletion(UUID userId, UUID deadlineId, boolean completed) {
        return apply(owned(userId, deadlineId), completed);
    }

    @Override
    public void syncFromChallenge(UUID userId, UUID deadlineId, boolean completed) {
        deadlines.findById(deadlineId)
                .filter(d -> d.userId().equals(userId) && d.completed() != completed)
                .ifPresent(d -> apply(d, completed));
    }

    /** Cambia el estado (idempotente), ajusta la experiencia una sola vez y publica el evento. */
    private Result apply(Deadline deadline, boolean completed) {
        Instant now = clock.instant();
        if (!deadline.setCompleted(completed, now)) {
            return new Result(deadline, 0);
        }
        int xpDelta = 0;
        if (completed && !deadline.xpAwarded()) {
            award.award(deadline.userId(), Deadline.EXPERIENCE);
            deadline.markExperienceAwarded(true);
            xpDelta = Deadline.EXPERIENCE;
        } else if (!completed && deadline.xpAwarded()) {
            revoke.revoke(deadline.userId(), Deadline.EXPERIENCE);
            deadline.markExperienceAwarded(false);
            xpDelta = -Deadline.EXPERIENCE;
        }
        Deadline saved = deadlines.save(deadline);
        weeklyLoads.refresh(saved.userId(), zone.localDate(saved.dueAt()));
        events.publish(new DeadlineCompletionChanged(saved.userId(), saved.id(), saved.completed(), now));
        return new Result(saved, xpDelta);
    }

    private void requireSubject(UUID userId, UUID subjectId) {
        if (subjectId != null && subjects.findOwned(userId, subjectId).isEmpty()) {
            throw new PlannerSubjectNotFoundException(subjectId);
        }
    }

    private Deadline owned(UUID userId, UUID deadlineId) {
        return deadlines.findById(deadlineId)
                .filter(d -> d.userId().equals(userId))
                .orElseThrow(() -> new DeadlineNotFoundException(deadlineId));
    }
}
