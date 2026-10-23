package com.synaptixfit.domain.model.training;

import java.util.Comparator;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/**
 * Elige ejercicios que pueden sustituir a otro: comparten un músculo principal y se ordenan por
 * parecido. Pesa más trabajar igual (misma categoría y modalidad) que usar el mismo material, porque
 * quien cambia un ejercicio suele hacerlo por no tener esa máquina o por variar.
 */
public final class ExerciseAlternatives {

    public static final int DEFAULT_LIMIT = 8;

    private ExerciseAlternatives() {
    }

    public static List<Exercise> rank(Exercise base, List<Exercise> candidates, int limit) {
        Set<Integer> targets = ids(base.targetMuscles());
        return candidates.stream()
                .filter(c -> c.active() && !c.id().equals(base.id()))
                .filter(c -> c.targetMuscles().stream().anyMatch(m -> targets.contains(m.id())))
                .sorted(Comparator.comparingDouble((Exercise c) -> -score(base, c)).thenComparing(Exercise::name))
                .limit(Math.max(1, limit))
                .toList();
    }

    static double score(Exercise base, Exercise c) {
        double score = 0;
        if (c.category() == base.category()) {
            score += 3;
        }
        if (c.modality() == base.modality()) {
            score += 2;
        }
        if (c.difficulty() == base.difficulty()) {
            score += 1;
        }
        Set<Integer> equipment = ids(base.equipment());
        if (c.equipment().stream().anyMatch(e -> equipment.contains(e.id()))) {
            score += 1.5;
        }
        Set<Integer> secondary = ids(base.secondaryMuscles());
        score += 0.25 * c.secondaryMuscles().stream().filter(m -> secondary.contains(m.id())).count();
        // Con vídeo se aprende mejor el gesto: a igualdad, primero los que lo tienen.
        if (c.gifUrl() != null && !c.gifUrl().isBlank()) {
            score += 0.5;
        }
        return score;
    }

    private static Set<Integer> ids(List<CatalogItem> items) {
        Set<Integer> out = new HashSet<>();
        items.forEach(i -> out.add(i.id()));
        return out;
    }
}
