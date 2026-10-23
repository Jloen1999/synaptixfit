package com.synaptixfit.domain.model.training.generation;

import com.synaptixfit.domain.model.training.ExerciseParameters;
import com.synaptixfit.domain.model.training.TrainingGoal;
import com.synaptixfit.domain.model.training.generation.RoutineProposal.ProposedDay;
import java.util.List;

/**
 * Transición suave entre objetivos: durante las primeras semanas tras cambiar de objetivo los
 * rangos de series, repeticiones y descanso se interpolan entre el objetivo anterior y el nuevo
 * (30 % la primera semana, 70 % la segunda, 100 % desde la tercera).
 */
public final class GoalTransition {

    private GoalTransition() {
    }

    /** Parámetros resultantes, factor de interpolación y motivo (null si no hay transición). */
    public record Transition(GoalParameters parameters, double factor, String reason) {
        public boolean active() {
            return factor < 1.0;
        }
    }

    public static Transition compute(TrainingGoal current, TrainingGoal previous, int weeksInNewGoal) {
        GoalParameters target = GoalParameters.of(current);
        if (previous == null || previous == current) {
            return new Transition(target, 1.0, null);
        }
        double factor = weeksInNewGoal <= 0 ? 0.30 : weeksInNewGoal <= 1 ? 0.70 : 1.0;
        if (factor >= 1.0) {
            return new Transition(target, 1.0, null);
        }
        GoalParameters old = GoalParameters.of(previous);
        int setsMin = lerp(old.setsMin(), target.setsMin(), factor);
        int setsMax = Math.max(setsMin, lerp(old.setsMax(), target.setsMax(), factor));
        int repsMin = lerp(old.repsMin(), target.repsMin(), factor);
        int repsMax = Math.max(repsMin, lerp(old.repsMax(), target.repsMax(), factor));
        int restMin = lerp(old.restMin(), target.restMin(), factor);
        int restMax = Math.max(restMin, lerp(old.restMax(), target.restMax(), factor));
        boolean newer = factor >= 0.5;
        GoalParameters interpolated = new GoalParameters(current, setsMin, setsMax, repsMin, repsMax, restMin, restMax,
                lerp(old.rpeMin(), target.rpeMin(), factor), lerp(old.rpeMax(), target.rpeMax(), factor),
                lerp(old.relativeIntensity(), target.relativeIntensity(), factor),
                lerp(old.exercisesPerDay(), target.exercisesPerDay(), factor),
                newer ? target.prioritizeCompound() : old.prioritizeCompound(),
                newer ? target.modalities() : old.modalities(),
                lerp(old.weeklyVolumeTarget(), target.weeklyVolumeTarget(), factor),
                newer ? target.allowsCircuit() : old.allowsCircuit());
        return new Transition(interpolated, factor, "Transición " + previous.label() + " → " + current.label()
                + " (semana " + (weeksInNewGoal + 1) + ")");
    }

    /** Ajusta series, repeticiones y descanso de cada ejercicio a los rangos interpolados. */
    public static List<ProposedDay> apply(List<ProposedDay> days, Transition transition) {
        if (!transition.active()) {
            return days;
        }
        GoalParameters p = transition.parameters();
        return days.stream().map(d -> d.mapExercises(e -> {
            ExerciseParameters x = e.parameters();
            return e.withParameters(RoutineRuleEngine.withSets(ExerciseParameters.clamped(x.sets(),
                    p.clampReps(x.reps()), p.clampRest(x.restSeconds()), x.weightKg(), x.weightsKg(),
                    x.targetDurationSeconds(), x.distanceMeters(), x.isometricSeconds()), p.clampSets(x.sets())));
        })).toList();
    }

    private static int lerp(int a, int b, double f) {
        return (int) Math.round(a + (b - a) * f);
    }

    private static double lerp(double a, double b, double f) {
        return a + (b - a) * f;
    }
}
