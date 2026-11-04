package com.synaptixfit.domain.model.training;

import com.synaptixfit.domain.model.shared.Guard;
import java.util.List;
import java.util.Objects;
import java.util.UUID;

/**
 * Plantilla de rutina lista para usar (ADR 0032): días de la semana con sus ejercicios, objetivo, si es para
 * casa o para semanas de exámenes, duración prevista y cuántas semanas dura el plan. Los textos llegan ya en
 * el idioma pedido.
 *
 * <p>Regla: todas las semanas repiten los mismos días; en la semana suave (descarga) cada ejercicio hace
 * una serie menos (mínimo una) para recuperarse sin perder el hábito.
 */
public record RoutineTemplate(UUID id, String code, String name, String description, TrainingGoal goal,
                              boolean atHome, boolean forExams, int minutes, int weeks, List<Day> days) {

    /** Día de la semana (1 = lunes) con sus ejercicios en orden. */
    public record Day(int dayNumber, List<Item> exercises) {
        public Day {
            Guard.range(dayNumber, "dayNumber", 1, 7);
            exercises = List.copyOf(exercises);
        }
    }

    /** Ejercicio de la plantilla. {@code holdSeconds}: segundos aguantando (planchas); nulo si son repeticiones. */
    public record Item(UUID exerciseId, int sets, int reps, int restSeconds, Integer holdSeconds) {
        public Item {
            Objects.requireNonNull(exerciseId, "exerciseId");
        }
    }

    public RoutineTemplate {
        Objects.requireNonNull(id, "id");
        days = List.copyOf(days);
    }

    /** Días que se entrena cada semana. */
    public int daysPerWeek() {
        return days.size();
    }

    /** Parámetros de un ejercicio en una semana del tipo dado (la suave quita una serie). */
    public static ExerciseParameters parametersFor(Item item, WeekType type) {
        int sets = type == WeekType.DELOAD ? Math.max(1, item.sets() - 1) : item.sets();
        return ExerciseParameters.clamped(sets, item.reps(), item.restSeconds(), null, null, null, null,
                item.holdSeconds());
    }
}
