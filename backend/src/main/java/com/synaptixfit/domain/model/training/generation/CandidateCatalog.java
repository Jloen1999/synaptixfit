package com.synaptixfit.domain.model.training.generation;

import com.synaptixfit.domain.model.training.Difficulty;
import com.synaptixfit.domain.model.training.Exercise;
import com.synaptixfit.domain.model.training.TrainingGoal;
import java.util.Comparator;
import java.util.List;

/**
 * «Catálogo inteligente» para la IA: solo los {@value #LIMIT} ejercicios aptos más afines al objetivo
 * (finalidad 50 %, compuesto 20 %, versatilidad 15 %, dificultad intermedia 10 % / principiante 5 %),
 * para no enviar el catálogo entero en el prompt.
 */
public final class CandidateCatalog {

    public static final int LIMIT = 60;

    private CandidateCatalog() {
    }

    public static List<Exercise> top(List<Exercise> catalog, TrainingProfile profile, TrainingGoal goal) {
        return catalog.stream()
                .filter(e -> ExerciseEligibility.eligible(e, profile))
                .sorted(Comparator.comparingDouble((Exercise e) -> -score(e, goal)).thenComparing(Exercise::name))
                .limit(LIMIT)
                .toList();
    }

    static double score(Exercise e, TrainingGoal goal) {
        double score = 0;
        if (e.hasPurpose(goal)) {
            score += 0.50;
        }
        if (e.isCompound()) {
            score += 0.20;
        }
        if (e.purposes().size() >= 2) {
            score += 0.15;
        }
        if (e.difficulty() == Difficulty.INTERMEDIATE) {
            score += 0.10;
        } else if (e.difficulty() == Difficulty.BEGINNER) {
            score += 0.05;
        }
        return Math.min(1, score);
    }
}
