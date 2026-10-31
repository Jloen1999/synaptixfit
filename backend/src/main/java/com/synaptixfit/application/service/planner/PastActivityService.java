package com.synaptixfit.application.service.planner;

import com.synaptixfit.application.port.input.planner.LogPastActivityUseCase;
import com.synaptixfit.application.port.input.planner.SetBlockCompletionUseCase;
import com.synaptixfit.domain.model.planner.ActivityType;
import com.synaptixfit.domain.model.planner.CalendarBlock;
import com.synaptixfit.domain.model.planner.PastActivity;
import com.synaptixfit.domain.model.planner.PlannerZone;
import com.synaptixfit.domain.model.planner.Priority;
import com.synaptixfit.domain.model.planner.TimeRange;
import com.synaptixfit.domain.port.output.planner.CalendarBlockRepositoryPort;
import java.time.Clock;
import java.time.Instant;
import java.util.UUID;

/**
 * Implementa {@link LogPastActivityUseCase}: guarda el bloque de deporte ya pasado y lo completa con
 * {@link SetBlockCompletionUseCase}, así se aplican las mismas reglas (topes de XP, carga física con el esfuerzo,
 * semana) que al marcarlo desde el calendario.
 */
public class PastActivityService implements LogPastActivityUseCase {

    private final CalendarBlockRepositoryPort blocks;
    private final SetBlockCompletionUseCase completion;
    private final PlannerZone zone;
    private final Clock clock;

    public PastActivityService(CalendarBlockRepositoryPort blocks, SetBlockCompletionUseCase completion,
                               PlannerZone zone, Clock clock) {
        this.blocks = blocks;
        this.completion = completion;
        this.zone = zone;
        this.clock = clock;
    }

    @Override
    public SetBlockCompletionUseCase.Result logPastActivity(Command command) {
        Instant now = clock.instant();
        PastActivity activity = new PastActivity(command.start(), command.minutes(), command.title(),
                command.effort());
        activity.requireLoggableAt(now);
        TimeRange range = activity.range();
        CalendarBlock.Details details = new CalendarBlock.Details(null, activity.title(), null, Priority.MEDIUM,
                false, null, null, null, null, null, null, null);
        CalendarBlock block = CalendarBlock.builder()
                .id(UUID.randomUUID())
                .userId(command.userId())
                .range(range)
                .dayOfWeek(zone.dayOfWeek(range.start()))
                .type(ActivityType.SPORT)
                .details(details)
                .fixed(false)
                .createdAt(now)
                .build();
        blocks.save(block);
        return completion.setCompletion(command.userId(), block.id(), true, activity.effort());
    }
}
