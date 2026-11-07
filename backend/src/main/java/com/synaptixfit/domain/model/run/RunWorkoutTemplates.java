package com.synaptixfit.domain.model.run;

import com.synaptixfit.domain.model.run.RunStep.Type;
import com.synaptixfit.domain.model.run.RunWorkout.Group;
import java.util.List;

/**
 * Plantillas de entreno de carrera listas para usar (ADR 0037). El nombre y la explicación en lenguaje sencillo los
 * pone el cliente en cada idioma a partir del código; aquí solo están los pasos. Se basan en los planes de inicio
 * habituales (alternar andar y correr), rodajes suaves, series cortas, cambios de ritmo y la tirada larga semanal.
 */
public final class RunWorkoutTemplates {

    /** Una plantilla: código estable y sus grupos de pasos. */
    public record Template(String code, List<Group> groups) {

        public Template {
            groups = List.copyOf(groups);
        }
    }

    public static final List<Template> ALL = List.of(
            new Template("START_WALK_RUN", List.of(
                    Group.once(RunStep.time(Type.WARMUP, 300)),
                    new Group(8, List.of(RunStep.time(Type.RUN, 60), RunStep.time(Type.RECOVER, 120))),
                    Group.once(RunStep.time(Type.COOLDOWN, 300)))),
            new Template("EASY_30", List.of(
                    Group.once(RunStep.time(Type.WARMUP, 300)),
                    Group.once(RunStep.time(Type.RUN, 1800)),
                    Group.once(RunStep.time(Type.COOLDOWN, 300)))),
            new Template("INTERVALS_6X800", List.of(
                    Group.once(RunStep.time(Type.WARMUP, 600)),
                    new Group(6, List.of(RunStep.distance(Type.RUN, 800), RunStep.time(Type.RECOVER, 120))),
                    Group.once(RunStep.time(Type.COOLDOWN, 600)))),
            new Template("PACE_CHANGES", List.of(
                    Group.once(RunStep.time(Type.WARMUP, 600)),
                    new Group(8, List.of(RunStep.time(Type.RUN, 60), RunStep.time(Type.RECOVER, 60))),
                    Group.once(RunStep.time(Type.COOLDOWN, 300)))),
            new Template("STEADY_20", List.of(
                    Group.once(RunStep.time(Type.WARMUP, 600)),
                    Group.once(RunStep.time(Type.RUN, 1200)),
                    Group.once(RunStep.time(Type.COOLDOWN, 600)))),
            new Template("LONG_RUN", List.of(
                    Group.once(RunStep.time(Type.WARMUP, 300)),
                    Group.once(RunStep.distance(Type.RUN, 10_000)),
                    Group.once(RunStep.time(Type.COOLDOWN, 300)))));

    private RunWorkoutTemplates() {
    }
}
