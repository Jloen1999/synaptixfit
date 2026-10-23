package com.synaptixfit.domain.model.training;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;

/**
 * Calentamiento y vuelta a la calma de una sesión: ejercicios de movilidad (antes) y estiramientos
 * (después) de los músculos principales que se van a trabajar, uno por músculo y como mucho
 * {@link #MAX_PER_PHASE}. Así cada parte dura unos 5 minutos y prepara lo que de verdad se usa.
 */
public record SessionBookends(List<Exercise> warmUp, List<Exercise> coolDown) {

    public static final int MAX_PER_PHASE = 4;

    public SessionBookends {
        warmUp = List.copyOf(warmUp);
        coolDown = List.copyOf(coolDown);
    }

    /** Músculos principales de la sesión, en el orden en que aparecen. */
    public static Set<Integer> targetMuscles(List<Exercise> session) {
        Set<Integer> ids = new LinkedHashSet<>();
        session.forEach(e -> e.targetMuscles().forEach(m -> ids.add(m.id())));
        return ids;
    }

    public static SessionBookends of(List<Exercise> session, List<Exercise> candidates) {
        Set<Integer> muscles = targetMuscles(session);
        List<Exercise> pool = candidates.stream().filter(Exercise::active)
                .sorted(Comparator.comparing((Exercise e) -> e.gifUrl() == null || e.gifUrl().isBlank())
                        .thenComparing(Exercise::name))
                .toList();
        return new SessionBookends(pick(pool, muscles, ExerciseCategory.MOBILITY),
                pick(pool, muscles, ExerciseCategory.STRETCHING));
    }

    /** Uno por músculo; si no hay de la categoría pedida, sirve yoga (movilidad y estiramiento a la vez). */
    private static List<Exercise> pick(List<Exercise> pool, Set<Integer> muscles, ExerciseCategory preferred) {
        List<Exercise> chosen = new ArrayList<>();
        for (Integer muscle : muscles) {
            if (chosen.size() == MAX_PER_PHASE) {
                break;
            }
            pool.stream()
                    .filter(e -> !chosen.contains(e))
                    .filter(e -> e.targetMuscles().stream().anyMatch(m -> m.id() == muscle))
                    .filter(e -> e.category() == preferred || e.category() == ExerciseCategory.YOGA)
                    .min(Comparator.comparing((Exercise e) -> e.category() != preferred))
                    .ifPresent(chosen::add);
        }
        return chosen;
    }
}
