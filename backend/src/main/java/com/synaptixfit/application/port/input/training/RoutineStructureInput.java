package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.training.ExerciseParameters;
import com.synaptixfit.domain.model.training.WeekType;
import java.util.List;
import java.util.UUID;

/** Estructura de entrada de una rutina (alta completa). Las semanas se numeran por posición. */
public final class RoutineStructureInput {

    private RoutineStructureInput() {
    }

    /** Semana: {@code type} nulo usa el tipo por defecto según su posición. */
    public record Week(String name, WeekType type, List<Day> days) {
        public Week {
            days = List.copyOf(days == null ? List.of() : days);
        }
    }

    /** Día de la semana (1-7). */
    public record Day(int dayNumber, String name, List<Exercise> exercises) {
        public Day {
            exercises = List.copyOf(exercises == null ? List.of() : exercises);
        }
    }

    /** Ejercicio del catálogo con sus parámetros, en el orden de la lista. */
    public record Exercise(UUID exerciseId, ExerciseParameters parameters) {
    }
}
