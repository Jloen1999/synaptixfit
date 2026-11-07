package com.synaptixfit.domain.model.run;

import com.synaptixfit.domain.exception.FieldValidationException;
import com.synaptixfit.domain.model.shared.Guard;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * Entreno de carrera por pasos (ADR 0037): una lista de grupos, cada uno con sus pasos y cuántas veces se repite
 * («6 × 800 m · 2 min recuperando» es un grupo de 2 pasos repetido 6 veces). Se pone en el calendario como evento
 * de tipo Entreno y, al grabarlo con el GPS, la app guía paso a paso.
 *
 * @param templateCode plantilla de la que salió (opcional), para que el cliente la reconozca
 */
public record RunWorkout(UUID id, UUID userId, String name, String templateCode, List<Group> groups,
                         Instant createdAt, Instant updatedAt) {

    public static final int NAME_MAX = 80;
    public static final int MAX_GROUPS = 20;
    public static final int MAX_STEPS_PER_GROUP = 6;
    public static final int MAX_REPEAT = 30;
    /** Pasos ya desplegados con sus repeticiones: más no cabe en una sesión razonable. */
    public static final int MAX_TOTAL_STEPS = 200;

    /** Pasos que se repiten {@code repeat} veces seguidas. */
    public record Group(int repeat, List<RunStep> steps) {

        public Group {
            Guard.range(repeat, "repeat", 1, MAX_REPEAT);
            Guard.notNull(steps, "steps");
            if (steps.isEmpty() || steps.size() > MAX_STEPS_PER_GROUP) {
                throw new FieldValidationException("steps", "OUT_OF_RANGE",
                        "a group needs between 1 and " + MAX_STEPS_PER_GROUP + " steps");
            }
            steps = List.copyOf(steps);
        }

        public static Group once(RunStep step) {
            return new Group(1, List.of(step));
        }
    }

    public RunWorkout {
        Guard.notNull(id, "id");
        Guard.notNull(userId, "userId");
        name = Guard.length(Guard.notBlank(name, "name").strip(), "name", 1, NAME_MAX);
        Guard.notNull(groups, "groups");
        if (groups.isEmpty() || groups.size() > MAX_GROUPS) {
            throw new FieldValidationException("groups", "OUT_OF_RANGE",
                    "a workout needs between 1 and " + MAX_GROUPS + " groups");
        }
        groups = List.copyOf(groups);
        if (totalSteps(groups) > MAX_TOTAL_STEPS) {
            throw new FieldValidationException("groups", "OUT_OF_RANGE",
                    "a workout can have up to " + MAX_TOTAL_STEPS + " steps");
        }
    }

    private static int totalSteps(List<Group> groups) {
        return groups.stream().mapToInt(g -> g.repeat() * g.steps().size()).sum();
    }

    /** Duración prevista en segundos (pasos de distancia al ritmo de referencia de {@link RunStep}). */
    public int estimatedSeconds() {
        return groups.stream()
                .mapToInt(g -> g.repeat() * g.steps().stream().mapToInt(RunStep::estimatedSeconds).sum())
                .sum();
    }

    public RunWorkout renamed(String newName, List<Group> newGroups, Instant now) {
        return new RunWorkout(id, userId, newName, templateCode, newGroups, createdAt, now);
    }
}
