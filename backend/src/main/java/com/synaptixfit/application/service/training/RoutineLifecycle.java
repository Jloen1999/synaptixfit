package com.synaptixfit.application.service.training;

import com.synaptixfit.domain.event.training.RoutineCompleted;
import com.synaptixfit.domain.event.training.RoutineDaysSkipped;
import com.synaptixfit.domain.event.training.RoutineDeactivated;
import com.synaptixfit.domain.model.training.Routine;
import com.synaptixfit.domain.model.training.RoutineStatus;
import com.synaptixfit.domain.port.output.event.DomainEventPublisherPort;
import com.synaptixfit.domain.port.output.training.RoutineRepositoryPort;
import java.time.Clock;
import java.util.List;
import java.util.UUID;

/**
 * Guarda una rutina aplicando las reglas que dependen de otras rutinas o de otros módulos, para que
 * {@link RoutineService}, {@link RoutineProgressService} y {@link TrainingSessionService} las apliquen
 * igual:
 * <ul>
 *   <li>Solo una rutina en curso: si pasa a activa, las demás activas del usuario se pausan.</li>
 *   <li>Si deja de estar en curso se publica {@link RoutineDeactivated} (el calendario borra sus bloques
 *       futuros) y, si fue por terminar el ciclo, también {@link RoutineCompleted}.</li>
 *   <li>Los días saltados se publican con {@link RoutineDaysSkipped}.</li>
 * </ul>
 * Los eventos salen siempre después de guardar.
 */
final class RoutineLifecycle {

    private final RoutineRepositoryPort routines;
    private final DomainEventPublisherPort events;
    private final Clock clock;

    RoutineLifecycle(RoutineRepositoryPort routines, DomainEventPublisherPort events, Clock clock) {
        this.routines = routines;
        this.events = events;
        this.clock = clock;
    }

    /** Guarda la rutina sabiendo en qué estado estaba antes del cambio. */
    Routine save(Routine routine, RoutineStatus before) {
        Routine saved = routines.save(routine);
        RoutineStatus now = saved.status();
        if (before != RoutineStatus.ACTIVE && now == RoutineStatus.ACTIVE) {
            pauseOthers(saved);
        }
        if (before == RoutineStatus.ACTIVE && now != RoutineStatus.ACTIVE) {
            RoutineDeactivated.Reason reason = now == RoutineStatus.COMPLETED
                    ? RoutineDeactivated.Reason.COMPLETED : RoutineDeactivated.Reason.PAUSED;
            events.publish(new RoutineDeactivated(saved.ownerId(), saved.id(), reason, clock.instant()));
        }
        if (before != RoutineStatus.COMPLETED && now == RoutineStatus.COMPLETED) {
            events.publish(new RoutineCompleted(saved.ownerId(), saved.id(), saved.name(), saved.startDate(),
                    clock.instant()));
        }
        return saved;
    }

    /** Guarda una rutina nueva (crear, duplicar, clonar): solo queda en curso si no hay otra. */
    Routine saveNew(Routine routine) {
        if (!routines.findActiveByOwner(routine.ownerId()).isEmpty()) {
            routine.pause();
        } else {
            routine.activate();
        }
        return routines.save(routine);
    }

    /** Avisa de los días que se han saltado (a mano o al completar uno posterior). */
    void daysSkipped(Routine routine, List<UUID> dayIds) {
        if (!dayIds.isEmpty()) {
            events.publish(new RoutineDaysSkipped(routine.ownerId(), routine.id(), dayIds, clock.instant()));
        }
    }

    private void pauseOthers(Routine current) {
        for (Routine other : routines.findActiveByOwner(current.ownerId())) {
            if (!other.id().equals(current.id()) && other.pause()) {
                routines.save(other);
                events.publish(new RoutineDeactivated(other.ownerId(), other.id(), RoutineDeactivated.Reason.PAUSED,
                        clock.instant()));
            }
        }
    }
}
