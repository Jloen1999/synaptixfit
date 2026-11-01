package com.synaptixfit.application.service.training;

import com.synaptixfit.application.port.input.training.GetPendingTrainingDayUseCase;
import com.synaptixfit.application.port.input.training.RestartRoutineUseCase;
import com.synaptixfit.application.port.input.training.SkipRoutineDayUseCase;
import com.synaptixfit.application.port.input.training.UnskipRoutineDayUseCase;
import com.synaptixfit.domain.exception.training.RoutineNotFoundException;
import com.synaptixfit.domain.model.training.PendingDay;
import com.synaptixfit.domain.model.training.Routine;
import com.synaptixfit.domain.model.training.RoutineSchedule;
import com.synaptixfit.domain.model.training.RoutineStatus;
import com.synaptixfit.domain.model.training.TrainingSession;
import com.synaptixfit.domain.port.output.event.DomainEventPublisherPort;
import com.synaptixfit.domain.port.output.training.RoutineCalendarPort;
import com.synaptixfit.domain.port.output.training.RoutineRepositoryPort;
import com.synaptixfit.domain.port.output.training.TrainingSessionRepositoryPort;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Avance de la rutina en curso: próximo día (regla única de {@link RoutineSchedule}, que usan también
 * Inicio y los avisos), saltar y recuperar días y repetir el ciclo. Guarda con {@link RoutineLifecycle}
 * para respetar la rutina única en curso y avisar al calendario.
 */
public class RoutineProgressService implements GetPendingTrainingDayUseCase, SkipRoutineDayUseCase,
        UnskipRoutineDayUseCase, RestartRoutineUseCase {

    private final RoutineRepositoryPort routines;
    private final TrainingSessionRepositoryPort sessions;
    private final RoutineCalendarPort calendar;
    private final RoutineLifecycle lifecycle;
    private final Clock clock;
    private final ZoneId zone;

    /** @param zone zona que define el «hoy» de la rutina (la de sesiones, indicadores y calendario) */
    public RoutineProgressService(RoutineRepositoryPort routines, TrainingSessionRepositoryPort sessions,
                                  RoutineCalendarPort calendar, DomainEventPublisherPort events, Clock clock,
                                  ZoneId zone) {
        this.routines = routines;
        this.sessions = sessions;
        this.calendar = calendar;
        this.lifecycle = new RoutineLifecycle(routines, events, clock);
        this.clock = clock;
        this.zone = zone;
    }

    @Override
    public Optional<PendingDay> pendingDay(UUID userId) {
        Optional<Routine> active = routines.findLatestActive(userId);
        if (active.isEmpty()) {
            return Optional.empty();
        }
        Routine routine = active.get();
        Instant now = clock.instant();
        Map<UUID, RoutineSchedule.OpenSession> open = new HashMap<>();
        // findOpen viene de más reciente a más antigua: se queda la última sesión abierta de cada día.
        for (TrainingSession s : sessions.findOpen(userId)) {
            if (s.dayId() != null && routine.findDay(s.dayId()).isPresent()) {
                open.putIfAbsent(s.dayId(), new RoutineSchedule.OpenSession(s.id(), s.startedAt()));
            }
        }
        Map<UUID, List<LocalDate>> planned = calendar.pendingBlockStarts(userId, routine.id()).entrySet().stream()
                .collect(Collectors.toMap(Map.Entry::getKey,
                        e -> e.getValue().stream().map(i -> LocalDate.ofInstant(i, zone)).toList()));
        return routine.nextPendingDay(new RoutineSchedule.Context(today(), now, open, planned));
    }

    @Override
    public Routine skip(UUID userId, UUID routineId, UUID dayId) {
        Routine routine = owned(userId, routineId);
        RoutineStatus before = routine.status();
        routine.skipDay(dayId, today());
        routine.finishCycleIfDone();
        Routine saved = lifecycle.save(routine, before);
        lifecycle.daysSkipped(saved, List.of(dayId));
        return saved;
    }

    @Override
    public Routine unskip(UUID userId, UUID routineId, UUID dayId) {
        Routine routine = owned(userId, routineId);
        RoutineStatus before = routine.status();
        if (!routine.unskipDay(dayId)) {
            return routine;
        }
        return lifecycle.save(routine, before);
    }

    @Override
    public Routine restart(UUID userId, UUID routineId) {
        Routine routine = owned(userId, routineId);
        RoutineStatus before = routine.status();
        routine.restart(today());
        return lifecycle.save(routine, before);
    }

    private Routine owned(UUID userId, UUID routineId) {
        return routines.findById(routineId).filter(r -> r.isOwnedBy(userId))
                .orElseThrow(() -> new RoutineNotFoundException(routineId));
    }

    private LocalDate today() {
        return LocalDate.ofInstant(clock.instant(), zone);
    }
}
