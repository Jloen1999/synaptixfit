package com.synaptixfit.domain.model.training.generation;

import com.synaptixfit.domain.model.training.ExerciseParameters;
import com.synaptixfit.domain.model.training.TrainingGoal;
import com.synaptixfit.domain.model.training.WeekType;
import java.util.List;
import java.util.UUID;
import java.util.function.UnaryOperator;

/**
 * Propuesta de rutina generada (no se guarda): el usuario la revisa, la edita y la guarda con el
 * alta normal de rutinas.
 */
public record RoutineProposal(String name, String description, TrainingGoal goal, List<ProposedWeek> weeks,
                              String split, List<String> adjustmentReasons, double totalLoadFactor,
                              boolean aiRefined, String aiNotice) {

    public RoutineProposal {
        weeks = List.copyOf(weeks);
        adjustmentReasons = List.copyOf(adjustmentReasons == null ? List.of() : adjustmentReasons);
    }

    public int durationWeeks() {
        return weeks.size();
    }

    public int exerciseCount() {
        return weeks.stream().flatMap(w -> w.days().stream()).mapToInt(d -> d.exercises().size()).sum();
    }

    public RoutineProposal withWeeks(List<ProposedWeek> newWeeks) {
        return new RoutineProposal(name, description, goal, newWeeks, split, adjustmentReasons, totalLoadFactor,
                aiRefined, aiNotice);
    }

    public RoutineProposal withAiResult(String newName, String newDescription, List<ProposedWeek> newWeeks) {
        return new RoutineProposal(newName, newDescription, goal, newWeeks, split, adjustmentReasons,
                totalLoadFactor, true, null);
    }

    public RoutineProposal withAiNotice(String notice) {
        return new RoutineProposal(name, description, goal, weeks, split, adjustmentReasons, totalLoadFactor,
                false, notice);
    }

    /** Semana propuesta. */
    public record ProposedWeek(int number, String name, WeekType type, List<ProposedDay> days) {
        public ProposedWeek {
            days = List.copyOf(days);
        }

        public ProposedWeek withName(String newName) {
            return new ProposedWeek(number, newName, type, days);
        }

        public ProposedWeek withDays(List<ProposedDay> newDays) {
            return new ProposedWeek(number, name, type, newDays);
        }
    }

    /** Día propuesto. */
    public record ProposedDay(int dayNumber, String name, List<ProposedExercise> exercises) {
        public ProposedDay {
            exercises = List.copyOf(exercises);
        }

        public ProposedDay withName(String newName) {
            return new ProposedDay(dayNumber, newName, exercises);
        }

        public ProposedDay withExercises(List<ProposedExercise> newExercises) {
            return new ProposedDay(dayNumber, name, newExercises);
        }

        public ProposedDay mapExercises(UnaryOperator<ProposedExercise> mapper) {
            return new ProposedDay(dayNumber, name, exercises.stream().map(mapper).toList());
        }
    }

    /** Ejercicio propuesto con sus parámetros. */
    public record ProposedExercise(UUID exerciseId, String exerciseName, ExerciseParameters parameters) {
        public ProposedExercise withParameters(ExerciseParameters newParameters) {
            return new ProposedExercise(exerciseId, exerciseName, newParameters);
        }
    }
}
