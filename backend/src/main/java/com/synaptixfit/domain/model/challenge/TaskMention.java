package com.synaptixfit.domain.model.challenge;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.UUID;

/**
 * Tarea de reto nombrada en otro sitio (ADR 0035): en la fila de Inicio del evento o la entrega que la hace avanzar y
 * en sus avisos. {@code title} y {@code milestoneId} nulos: el propio reto (sin tareas, se completa con su entrega).
 */
public record TaskMention(UUID challengeId, String challengeTitle, UUID milestoneId, String title) {

    public TaskMention {
        Objects.requireNonNull(challengeId, "challengeId");
    }

    static TaskMention of(Challenge c, Milestone m) {
        return m == null ? new TaskMention(c.id(), c.title(), null, null)
                : new TaskMention(c.id(), c.title(), m.id(), m.title());
    }

    /**
     * Cada tarea de {@code challenges} por su id, para nombrarla en los eventos asignados a ella (todos, hechos o no:
     * un evento recién marcado sigue diciendo qué tarea adelantó).
     */
    public static Map<UUID, TaskMention> byMilestone(List<Challenge> challenges) {
        Map<UUID, TaskMention> out = new HashMap<>();
        for (Challenge c : challenges) {
            for (Milestone m : c.milestones()) {
                out.put(m.id(), of(c, m));
            }
        }
        return out;
    }

    /**
     * Tareas (o retos sin tareas) que se completan con cada entrega o examen, por el id de la entrega. Los días de
     * rutina no cuentan: no son entregas.
     */
    public static Map<UUID, List<TaskMention>> byDeadline(List<Challenge> challenges) {
        Map<UUID, List<TaskMention>> out = new HashMap<>();
        for (Challenge c : challenges) {
            if (c.milestones().isEmpty()) {
                addDeadline(out, c.link(), of(c, null));
            }
            for (Milestone m : c.milestones()) {
                addDeadline(out, m.link(), of(c, m));
            }
        }
        return out;
    }

    private static void addDeadline(Map<UUID, List<TaskMention>> out, ChallengeLink link, TaskMention mention) {
        if (link != null && link.type() != LinkType.ROUTINE_DAY) {
            out.computeIfAbsent(link.entityId(), k -> new ArrayList<>()).add(mention);
        }
    }

    /**
     * Tareas (o retos sin tareas) que se completan al entrenar un día de rutina, por el id de ese día: la fila del
     * entreno de Inicio las nombra igual que su aviso (ADR 0035).
     */
    public static Map<UUID, List<TaskMention>> byRoutineDay(List<Challenge> challenges) {
        Map<UUID, List<TaskMention>> out = new HashMap<>();
        for (Challenge c : challenges) {
            if (c.milestones().isEmpty()) {
                addRoutineDay(out, c.link(), of(c, null));
            }
            for (Milestone m : c.milestones()) {
                addRoutineDay(out, m.link(), of(c, m));
            }
        }
        return out;
    }

    private static void addRoutineDay(Map<UUID, List<TaskMention>> out, ChallengeLink link, TaskMention mention) {
        if (link != null && link.type() == LinkType.ROUTINE_DAY) {
            out.computeIfAbsent(link.entityId(), k -> new ArrayList<>()).add(mention);
        }
    }
}
