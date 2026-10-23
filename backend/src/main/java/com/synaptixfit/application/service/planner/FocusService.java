package com.synaptixfit.application.service.planner;

import com.synaptixfit.application.port.input.gamification.AwardExperienceUseCase;
import com.synaptixfit.application.port.input.planner.GetFocusStatsUseCase;
import com.synaptixfit.application.port.input.planner.RecordFocusSessionUseCase;
import com.synaptixfit.domain.event.planner.FocusSessionCompleted;
import com.synaptixfit.domain.exception.planner.CalendarBlockNotFoundException;
import com.synaptixfit.domain.exception.planner.PlannerSubjectNotFoundException;
import com.synaptixfit.domain.model.planner.CalendarBlock;
import com.synaptixfit.domain.model.planner.FocusRewards;
import com.synaptixfit.domain.model.planner.FocusSession;
import com.synaptixfit.domain.model.planner.FocusStats;
import com.synaptixfit.domain.model.planner.PlannerZone;
import com.synaptixfit.domain.port.output.event.DomainEventPublisherPort;
import com.synaptixfit.domain.port.output.planner.CalendarBlockRepositoryPort;
import com.synaptixfit.domain.port.output.planner.FocusSessionRepositoryPort;
import com.synaptixfit.domain.port.output.planner.SubjectDirectoryPort;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

/**
 * Registro y estadísticas de los ciclos Pomodoro. Una fase de concentración completada da XP con
 * tope diario ({@link FocusRewards}, aplicado aquí porque el tope se calcula con la XP guardada en
 * {@code sesiones_focus}) y publica {@link FocusSessionCompleted} para indicadores e insignias.
 */
public class FocusService implements RecordFocusSessionUseCase, GetFocusStatsUseCase {

    private final FocusSessionRepositoryPort sessions;
    private final CalendarBlockRepositoryPort blocks;
    private final SubjectDirectoryPort subjects;
    private final AwardExperienceUseCase award;
    private final DomainEventPublisherPort events;
    private final PlannerZone zone;
    private final Clock clock;

    public FocusService(FocusSessionRepositoryPort sessions, CalendarBlockRepositoryPort blocks,
                        SubjectDirectoryPort subjects, AwardExperienceUseCase award, DomainEventPublisherPort events,
                        PlannerZone zone, Clock clock) {
        this.sessions = sessions;
        this.blocks = blocks;
        this.subjects = subjects;
        this.award = award;
        this.events = events;
        this.zone = zone;
        this.clock = clock;
    }

    @Override
    public Result record(Command command) {
        Instant now = clock.instant();
        LocalDate today = zone.today(now);
        LocalDate date = command.date() == null ? today : command.date();
        if (date.isAfter(today)) {
            date = today;
        }
        UUID subjectId = command.subjectId();
        if (command.blockId() != null) {
            CalendarBlock block = blocks.findById(command.blockId())
                    .filter(b -> b.userId().equals(command.userId()))
                    .orElseThrow(() -> new CalendarBlockNotFoundException(command.blockId()));
            if (subjectId == null) {
                subjectId = block.subjectId();
            }
        }
        if (command.subjectId() != null && subjects.findOwned(command.userId(), command.subjectId()).isEmpty()) {
            throw new PlannerSubjectNotFoundException(command.subjectId());
        }
        FocusSession session = new FocusSession(UUID.randomUUID(), command.userId(), command.phase(),
                command.durationMinutes(), command.cycles(), command.completed(), date, command.blockId(), subjectId,
                0, now);
        FocusRewards.Reward reward = FocusRewards.evaluate(session, today, sessions.sumXpAwarded(command.userId(), today));
        int xp = reward.xp();
        FocusSession saved = sessions.save(session.withXpAwarded(xp));
        if (xp > 0) {
            award.award(command.userId(), xp);
        }
        if (saved.isCompletedFocus()) {
            events.publish(new FocusSessionCompleted(saved.userId(), saved.id(), saved.date(), saved.durationMinutes(),
                    saved.blockId(), saved.subjectId(), xp, now));
        }
        return new Result(saved, reward.status());
    }

    @Override
    public FocusStats getStats(UUID userId, LocalDate date) {
        LocalDate day = date == null ? zone.today(clock.instant()) : date;
        LocalDate monday = PlannerZone.mondayOf(day);
        return FocusStats.of(sessions.findByUserBetween(userId, monday, monday.plusDays(6)), monday, day);
    }
}
