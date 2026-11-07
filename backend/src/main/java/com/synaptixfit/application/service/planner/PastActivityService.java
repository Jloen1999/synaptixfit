package com.synaptixfit.application.service.planner;

import com.synaptixfit.application.port.input.planner.CompletePlannedActivityUseCase;
import com.synaptixfit.application.port.input.planner.LogPastActivityUseCase;
import com.synaptixfit.application.port.input.planner.SetBlockCompletionUseCase;
import com.synaptixfit.domain.event.planner.SportBlockCompletionChanged;
import com.synaptixfit.domain.exception.planner.PlannerSubjectNotFoundException;
import com.synaptixfit.domain.model.planner.ActivityType;
import com.synaptixfit.domain.model.planner.CalendarBlock;
import com.synaptixfit.domain.model.shared.Guard;
import com.synaptixfit.domain.model.planner.PastActivity;
import com.synaptixfit.domain.model.planner.PlannerZone;
import com.synaptixfit.domain.model.planner.Priority;
import com.synaptixfit.domain.model.planner.TimeRange;
import com.synaptixfit.domain.port.output.event.DomainEventPublisherPort;
import com.synaptixfit.domain.port.output.planner.CalendarBlockRepositoryPort;
import com.synaptixfit.domain.port.output.planner.LoggedActivityRepositoryPort;
import com.synaptixfit.domain.port.output.planner.SubjectDirectoryPort;
import java.time.Clock;
import java.time.Instant;
import java.util.UUID;

/**
 * Implementa {@link LogPastActivityUseCase}: guarda el bloque ya pasado (deporte o estudio) y lo completa con
 * {@link SetBlockCompletionUseCase}, así se aplican las mismas reglas (topes de XP, carga física con el esfuerzo o
 * carga cognitiva, semana) que al marcarlo desde el calendario. La asignatura se comprueba con
 * {@link SubjectDirectoryPort}. También implementa {@link CompletePlannedActivityUseCase}: dejar hecho como actividad un
 * evento ya en el calendario (la carrera grabada desde su entreno, ADR 0037).
 */
public class PastActivityService implements LogPastActivityUseCase, CompletePlannedActivityUseCase {

    private final CalendarBlockRepositoryPort blocks;
    private final SubjectDirectoryPort subjects;
    private final SetBlockCompletionUseCase completion;
    private final PlannerZone zone;
    private final Clock clock;
    private final LoggedActivityRepositoryPort logged;
    private final DomainEventPublisherPort events;

    /**
     * @param logged donde se guardan la clase, los minutos reales y la distancia del deporte
     * @param events para que la carga física de un evento hecho como actividad cuente sus minutos reales
     */
    public PastActivityService(CalendarBlockRepositoryPort blocks, SubjectDirectoryPort subjects,
                               SetBlockCompletionUseCase completion, PlannerZone zone, Clock clock,
                               LoggedActivityRepositoryPort logged, DomainEventPublisherPort events) {
        this.logged = logged;
        this.events = events;
        this.blocks = blocks;
        this.subjects = subjects;
        this.completion = completion;
        this.zone = zone;
        this.clock = clock;
    }

    @Override
    public SetBlockCompletionUseCase.Result logPastActivity(LogPastActivityUseCase.Command command) {
        Instant now = clock.instant();
        PastActivity activity = new PastActivity(command.start(), command.minutes(), command.title(),
                command.effort(), command.type(), command.subjectId(), command.kind(), command.distanceMeters(),
                command.source());
        activity.requireLoggableAt(now);
        if (activity.subjectId() != null && subjects.findOwned(command.userId(), activity.subjectId()).isEmpty()) {
            throw new PlannerSubjectNotFoundException(activity.subjectId());
        }
        TimeRange range = activity.range();
        CalendarBlock.Details details = new CalendarBlock.Details(activity.subjectId(), activity.title(), null,
                Priority.MEDIUM, false, null, null, null, null, null, null, null);
        CalendarBlock block = CalendarBlock.builder()
                .id(UUID.randomUUID())
                .userId(command.userId())
                .range(range)
                .dayOfWeek(zone.dayOfWeek(range.start()))
                .type(activity.type())
                .details(details)
                .fixed(false)
                .createdAt(now)
                .build();
        blocks.save(block);
        SetBlockCompletionUseCase.Result result = completion.setCompletion(command.userId(), block.id(), true,
                activity.effort());
        if (activity.type() == ActivityType.SPORT) {
            logged.save(block.id(), command.userId(), activity.kind(), activity.minutes(), activity.distanceMeters(),
                    activity.source(), now);
            syncLoadWithRealMinutes(command.userId(), result.block(), activity.effort(), activity.minutes(), now);
        }
        return result;
    }

    @Override
    public SetBlockCompletionUseCase.Result completePlannedActivity(CompletePlannedActivityUseCase.Command command) {
        int effort = Guard.range(command.effort(), "effort", 1, 10);
        SetBlockCompletionUseCase.Result result = completion.setCompletion(command.userId(), command.blockId(), true,
                effort);
        Instant now = clock.instant();
        logged.save(command.blockId(), command.userId(), command.kind(), command.minutes(),
                command.distanceMeters(), command.source(), now);
        syncLoadWithRealMinutes(command.userId(), result.block(), effort, command.minutes(), now);
        return result;
    }

    /**
     * La carga física cuenta los minutos hechos, no los que ocupa el evento en el calendario (mínimo 30; ADR 0037):
     * se vuelve a sincronizar con ellos (el oyente de carga es idempotente y actualiza el registro del evento).
     */
    private void syncLoadWithRealMinutes(UUID userId, CalendarBlock block, Integer effort, int minutes, Instant now) {
        if (minutes != block.range().minutes()) {
            events.publish(new SportBlockCompletionChanged(userId, block.id(), zone.localDate(block.start()), effort,
                    minutes, true, now));
        }
    }
}
