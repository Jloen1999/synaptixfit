package com.synaptixfit.domain.model.run;

import com.synaptixfit.domain.model.run.RunStep.Type;
import com.synaptixfit.domain.model.run.RunWorkout.Group;
import java.util.List;
import java.util.Optional;
import java.util.stream.Stream;

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

    /**
     * Plan «Empieza a correr» (ADR 0054): el esquema clásico de Couch to 5K del NHS, 9 semanas y 3 salidas por semana,
     * de alternar 1 min corriendo y 1,5 andando a 30 min seguidos. Cada salida empieza y acaba con 5 min andando a paso
     * vivo. Las semanas 5 y 6 cambian de una salida a otra (_1, _2, _3). No se ofrecen sueltas en «Crear entreno»:
     * los crea la plantilla de rutina, uno por salida distinta.
     */
    public static final List<Template> COUCH_TO_5K = List.of(
            walkRun("C25K_W1", new Group(8, List.of(run(60), walk(90)))),
            walkRun("C25K_W2", new Group(6, List.of(run(90), walk(120)))),
            walkRun("C25K_W3", new Group(2, List.of(run(90), walk(90), run(180), walk(180)))),
            walkRun("C25K_W4", Group.once(run(180)), Group.once(walk(90)), Group.once(run(300)),
                    Group.once(walk(150)), Group.once(run(180)), Group.once(walk(90)), Group.once(run(300))),
            walkRun("C25K_W5_1", new Group(3, List.of(run(300), walk(180)))),
            walkRun("C25K_W5_2", Group.once(run(480)), Group.once(walk(300)), Group.once(run(480))),
            walkRun("C25K_W5_3", Group.once(run(1200))),
            walkRun("C25K_W6_1", Group.once(run(300)), Group.once(walk(180)), Group.once(run(480)),
                    Group.once(walk(180)), Group.once(run(300))),
            walkRun("C25K_W6_2", Group.once(run(600)), Group.once(walk(180)), Group.once(run(600))),
            walkRun("C25K_W6_3", Group.once(run(1500))),
            walkRun("C25K_W7", Group.once(run(1500))),
            walkRun("C25K_W8", Group.once(run(1680))),
            walkRun("C25K_W9", Group.once(run(1800))));

    private RunWorkoutTemplates() {
    }

    /** Plantilla por código, también las del plan «Empieza a correr». */
    public static Optional<Template> find(String code) {
        return Stream.concat(ALL.stream(), COUCH_TO_5K.stream()).filter(t -> t.code().equals(code)).findFirst();
    }

    private static Template walkRun(String code, Group... main) {
        List<Group> groups = new java.util.ArrayList<>();
        groups.add(Group.once(RunStep.time(Type.WARMUP, 300)));
        groups.addAll(List.of(main));
        groups.add(Group.once(RunStep.time(Type.COOLDOWN, 300)));
        return new Template(code, groups);
    }

    private static RunStep run(int seconds) {
        return RunStep.time(Type.RUN, seconds);
    }

    private static RunStep walk(int seconds) {
        return RunStep.time(Type.RECOVER, seconds);
    }
}
