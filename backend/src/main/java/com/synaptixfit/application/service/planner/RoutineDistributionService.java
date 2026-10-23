package com.synaptixfit.application.service.planner;

import com.synaptixfit.application.port.input.planner.DistributeRoutineUseCase;
import com.synaptixfit.domain.exception.planner.PlannerRoutineNotFoundException;
import com.synaptixfit.domain.model.planner.CalendarBlock;
import com.synaptixfit.domain.model.planner.PlannerZone;
import com.synaptixfit.domain.model.planner.RoutineDistribution;
import com.synaptixfit.domain.model.planner.RoutineRef;
import com.synaptixfit.domain.model.shared.Guard;
import com.synaptixfit.domain.port.output.planner.CalendarBlockRepositoryPort;
import com.synaptixfit.domain.port.output.planner.RoutineDirectoryPort;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;
import java.util.UUID;

/** Distribución de una rutina en el calendario (bloques de deporte vinculados a sus días). */
public class RoutineDistributionService implements DistributeRoutineUseCase {

    static final LocalTime DEFAULT_START = LocalTime.of(8, 0);
    /** Horizonte en el que se buscan conflictos: una rutina larga no pasa de un año. */
    private static final int HORIZON_DAYS = 400;

    private final CalendarBlockRepositoryPort blocks;
    private final RoutineDirectoryPort routines;
    private final WeeklyLoadService weeklyLoads;
    private final PlannerZone zone;
    private final Clock clock;

    public RoutineDistributionService(CalendarBlockRepositoryPort blocks, RoutineDirectoryPort routines,
                                      WeeklyLoadService weeklyLoads, PlannerZone zone, Clock clock) {
        this.blocks = blocks;
        this.routines = routines;
        this.weeklyLoads = weeklyLoads;
        this.zone = zone;
        this.clock = clock;
    }

    @Override
    public List<CalendarBlock> distribute(Command command) {
        Guard.range(command.durationMinutes(), "durationMinutes", 30, 240);
        Instant now = clock.instant();
        RoutineRef routine = routines.findOwnedWithDays(command.userId(), command.routineId())
                .orElseThrow(() -> new PlannerRoutineNotFoundException(command.routineId()));
        LocalDate start = command.startDate() == null ? zone.today(now) : command.startDate();
        LocalTime preferred = command.preferredStart() == null ? DEFAULT_START : command.preferredStart();
        Instant from = zone.startOfDay(start.isBefore(zone.today(now)) ? zone.today(now) : start);
        List<CalendarBlock> existing = blocks.findOverlapping(command.userId(), from,
                from.plus(java.time.Duration.ofDays(HORIZON_DAYS)), null);
        List<CalendarBlock> created = RoutineDistribution.distribute(command.userId(), routine,
                command.weekdays() == null ? java.util.Set.of() : command.weekdays(), start, preferred,
                command.durationMinutes(), existing, zone, now, UUID::randomUUID);
        List<CalendarBlock> saved = blocks.saveAll(created);
        saved.stream().map(b -> PlannerZone.mondayOf(zone.localDate(b.start()))).distinct()
                .forEach(monday -> weeklyLoads.refresh(command.userId(), monday));
        return saved;
    }
}
