package com.synaptixfit.domain.model.challenge;

import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.UUID;

/**
 * Tarea de reto pendiente que tiene fecha (ADR 0035). Una tarea no tiene fecha propia: la toma de lo que la hace
 * avanzar, su ancla. Se usa en Inicio (el evento o la entrega de hoy dice qué tarea adelanta) y en los avisos
 * (un aviso de esa entrega o evento menciona la tarea; si no hay ninguno, la tarea tiene el suyo).
 *
 * <ul>
 *   <li>Ligada a una entrega o examen: su fecha límite.</li>
 *   <li>Con eventos del calendario asignados: el siguiente sin hacer.</li>
 *   <li>Ligada a un día de rutina: el evento de entreno que refleja ese día, si está en el calendario; si no, la
 *       fecha prevista de ese día (solo si es el próximo día pendiente de la rutina).</li>
 * </ul>
 * Un reto sin tareas que se completa con su entrega cuenta como una tarea sin título ({@code title} nulo).
 *
 * @param anchorId id de la entrega, del evento o del día de rutina
 * @param at       cuándo toca (fecha límite, inicio del evento o comienzo del día previsto)
 */
public record DatedTask(UUID challengeId, String challengeTitle, UUID milestoneId, String title, Anchor anchor,
                        UUID anchorId, Instant at) {

    /** Qué da la fecha a la tarea. */
    public enum Anchor { DEADLINE, EVENT, ROUTINE_DAY }

    public DatedTask {
        Objects.requireNonNull(challengeId, "challengeId");
        Objects.requireNonNull(anchor, "anchor");
        Objects.requireNonNull(anchorId, "anchorId");
        Objects.requireNonNull(at, "at");
    }

    /**
     * Evento del calendario que puede dar fecha a una tarea.
     *
     * @param milestoneId  tarea a la que está asignado (nula si ninguna)
     * @param routineDayId día de rutina que refleja (eventos de entreno de una rutina)
     */
    public record EventRef(UUID id, UUID milestoneId, UUID routineDayId, Instant start, boolean completed) {
    }

    /** Próximo día pendiente de la rutina en curso y cuándo empieza ese día. */
    public record RoutineDayRef(UUID dayId, Instant at) {
    }

    /** Cómo se nombra esta tarea en el aviso de su ancla o en Inicio. */
    public TaskMention mention() {
        return new TaskMention(challengeId, challengeTitle, milestoneId, title);
    }

    /**
     * Tareas pendientes con fecha de {@code challenges} desde {@code now}. Solo cuentan los retos en curso ahora (ni
     * por empezar ni vencidos: aún o ya no se pueden avanzar) y las tareas no bloqueadas por dependencias.
     */
    public static List<DatedTask> of(List<Challenge> challenges, List<EventRef> events, RoutineDayRef routineDay,
                                     Instant now) {
        List<DatedTask> out = new ArrayList<>();
        for (Challenge c : challenges) {
            if (c.status(now) != ChallengeStatus.ACTIVE) {
                continue;
            }
            if (c.milestones().isEmpty()) {
                deadlineOf(c, c.link(), now).ifPresent(at -> out.add(new DatedTask(c.id(), c.title(), null, null,
                        Anchor.DEADLINE, c.link().entityId(), at)));
                continue;
            }
            for (Milestone m : c.milestones()) {
                if (m.completed() || m.isLocked()) {
                    continue;
                }
                anchorOf(c, m, events, routineDay, now).ifPresent(out::add);
            }
        }
        out.sort(Comparator.comparing(DatedTask::at));
        return out;
    }

    private static Optional<DatedTask> anchorOf(Challenge c, Milestone m, List<EventRef> events,
                                                RoutineDayRef routineDay, Instant now) {
        ChallengeLink link = m.link();
        if (link != null && link.type() == LinkType.ROUTINE_DAY) {
            Optional<EventRef> event = next(events.stream()
                    .filter(e -> link.entityId().equals(e.routineDayId())).toList(), now);
            if (event.isPresent()) {
                return event.map(e -> task(c, m, Anchor.EVENT, e.id(), e.start()));
            }
            // El día previsto vale mientras no ha terminado (at es su comienzo).
            if (routineDay != null && link.entityId().equals(routineDay.dayId())
                    && routineDay.at().plus(Duration.ofDays(1)).isAfter(now)) {
                return Optional.of(task(c, m, Anchor.ROUTINE_DAY, routineDay.dayId(), routineDay.at()));
            }
            return Optional.empty();
        }
        if (link != null) {
            return deadlineOf(c, link, now).map(at -> task(c, m, Anchor.DEADLINE, link.entityId(), at));
        }
        return next(events.stream().filter(e -> m.id().equals(e.milestoneId())).toList(), now)
                .map(e -> task(c, m, Anchor.EVENT, e.id(), e.start()));
    }

    private static Optional<Instant> deadlineOf(Challenge c, ChallengeLink link, Instant now) {
        if (link == null || link.type() == LinkType.ROUTINE_DAY) {
            return Optional.empty();
        }
        return c.linkedDeadline(link).filter(d -> !d.completed() && d.dueAt() != null && !d.dueAt().isBefore(now))
                .map(LinkedDeadline::dueAt);
    }

    /** El siguiente evento sin hacer que aún no ha empezado. */
    private static Optional<EventRef> next(List<EventRef> events, Instant now) {
        return events.stream().filter(e -> !e.completed() && !e.start().isBefore(now))
                .min(Comparator.comparing(EventRef::start));
    }

    private static DatedTask task(Challenge c, Milestone m, Anchor anchor, UUID anchorId, Instant at) {
        return new DatedTask(c.id(), c.title(), m.id(), m.title(), anchor, anchorId, at);
    }
}
