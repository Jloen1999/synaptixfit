package com.synaptixfit.domain.model.training;

import com.synaptixfit.domain.model.shared.Guard;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.UUID;

/**
 * Plantilla de rutina lista para usar (ADR 0032): días de la semana con sus ejercicios, objetivo, lugar, nivel,
 * si es para semanas de exámenes, duración prevista y cuántas semanas dura el plan. Los textos llegan ya en el
 * idioma pedido. Puede traer días de carrera (ADR 0043): se hacen en Entreno › Correr con un entreno de carrera,
 * no en la rutina, porque una carrera se graba con el GPS y cuenta como actividad.
 *
 * <p>Regla: todas las semanas repiten los mismos días; en la semana suave (descarga) cada ejercicio hace
 * una serie menos (mínimo una) para recuperarse sin perder el hábito.
 */
public record RoutineTemplate(UUID id, String code, String name, String description, TrainingGoal goal,
                              TemplatePlace place, TemplateLevel level, boolean forExams, int minutes, int weeks,
                              List<Day> days, List<RunDay> runDays) {

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

    /**
     * Día de la semana para salir a correr con el entreno de carrera {@code workoutCode} (de
     * {@code RunWorkoutTemplates}); {@code workoutName} es su nombre en el idioma pedido.
     */
    public record RunDay(int dayNumber, String workoutCode, String workoutName) {
        public RunDay {
            Guard.range(dayNumber, "dayNumber", 1, 7);
            Objects.requireNonNull(workoutCode, "workoutCode");
        }
    }

    public RoutineTemplate {
        Objects.requireNonNull(id, "id");
        Guard.range(weeks, "weeks", 1, 12);
        Guard.range(minutes, "minutes", 10, 180);
        place = place == null ? TemplatePlace.GYM : place;
        level = level == null ? TemplateLevel.BEGINNER : level;
        days = List.copyOf(days);
        runDays = runDays == null ? List.of() : List.copyOf(runDays);
    }

    /** Para casa: lo que las apps anteriores leían como {@code atHome}. */
    public boolean atHome() {
        return place == TemplatePlace.HOME;
    }

    /** Días que se entrena cada semana, contando los de carrera. */
    public int daysPerWeek() {
        return days.size() + runDays.size();
    }

    /** Entrenos de carrera distintos que pide la plantilla, en el orden de la semana. */
    public List<RunDay> distinctRunWorkouts() {
        Map<String, RunDay> byCode = new LinkedHashMap<>();
        runDays.stream().sorted(Comparator.comparingInt(RunDay::dayNumber))
                .forEach(d -> byCode.putIfAbsent(d.workoutCode(), d));
        return List.copyOf(byCode.values());
    }

    /** Parámetros de un ejercicio en una semana del tipo dado (la suave quita una serie). */
    public static ExerciseParameters parametersFor(Item item, WeekType type) {
        int sets = type == WeekType.DELOAD ? Math.max(1, item.sets() - 1) : item.sets();
        return ExerciseParameters.clamped(sets, item.reps(), item.restSeconds(), null, null, null, null,
                item.holdSeconds());
    }
}
