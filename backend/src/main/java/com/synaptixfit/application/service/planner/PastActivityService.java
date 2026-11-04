package com.synaptixfit.application.service.planner;

import com.synaptixfit.application.port.input.planner.LogPastActivityUseCase;
import com.synaptixfit.application.port.input.planner.SetBlockCompletionUseCase;
import com.synaptixfit.domain.exception.planner.PlannerSubjectNotFoundException;
import com.synaptixfit.domain.model.planner.ActivityType;
import com.synaptixfit.domain.model.planner.CalendarBlock;
import com.synaptixfit.domain.model.planner.PastActivity;
import com.synaptixfit.domain.model.planner.PlannerZone;
import com.synaptixfit.domain.model.planner.Priority;
import com.synaptixfit.domain.model.planner.TimeRange;
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
 * {@link SubjectDirectoryPort}.
 */
public class PastActivityService implements LogPastActivityUseCase {

    private final CalendarBlockRepositoryPort blocks;
    private final SubjectDirectoryPort subjects;
    private final SetBlockCompletionUseCase completion;
    private final PlannerZone zone;
    private final Clock clock;
    private final LoggedActivityRepositoryPort logged;

    public PastActivityService(CalendarBlockRepositoryPort blocks, SubjectDirectoryPort subjects,
                               SetBlockCompletionUseCase completion, PlannerZone zone, Clock clock) {
        this(blocks, subjects, completion, zone, clock, null);
    }

    /** @param logged donde se guardan la clase, los minutos reales y la distancia del deporte (nulo: no se guardan) */
    public PastActivityService(CalendarBlockRepositoryPort blocks, SubjectDirectoryPort subjects,
                               SetBlockCompletionUseCase completion, PlannerZone zone, Clock clock,
                               LoggedActivityRepositoryPort logged) {
        this.logged = logged;
        this.blocks = blocks;
        this.subjects = subjects;
        this.completion = completion;
        this.zone = zone;
        this.clock = clock;
    }

    @Override
    public SetBlockCompletionUseCase.Result logPastActivity(Command command) {
        Instant now = clock.instant();
        PastActivity activity = new PastActivity(command.start(), command.minutes(), command.title(),
                command.effort(), command.type(), command.subjectId(), command.kind(), command.distanceMeters());
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
        if (logged != null && activity.type() == ActivityType.SPORT) {
            logged.save(block.id(), command.userId(), activity.kind(), activity.minutes(), activity.distanceMeters(),
                    now);
        }
        return result;
    }
}
