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
 *
 * <p>ADR 0054: cada día trae el nombre de la sesión («Piernas, pecho y espalda»), cada ejercicio su rango de
 * repeticiones y cuántas deben sobrar, y las salidas a correr pueden cambiar cada semana (plan progresivo). Una
 * plantilla retirada ({@code active} falso) ya no se ofrece, pero se sigue leyendo; las rutinas que se crearon con
 * ella son copias propias y no cambian.
 */
public record RoutineTemplate(UUID id, String code, String name, String description, TrainingGoal goal,
                              TemplatePlace place, TemplateLevel level, boolean forExams, int minutes, int weeks,
                              List<Day> days, List<RunDay> runDays, boolean active) {

    /** Día de la semana (1 = lunes) con el nombre de la sesión (nulo si no tiene) y sus ejercicios en orden. */
    public record Day(int dayNumber, String name, List<Item> exercises) {
        public Day {
            Guard.range(dayNumber, "dayNumber", 1, 7);
            name = name == null || name.isBlank() ? null : name.strip();
            exercises = List.copyOf(exercises);
        }

        public Day(int dayNumber, List<Item> exercises) {
            this(dayNumber, null, exercises);
        }
    }

    /**
     * Ejercicio de la plantilla. {@code holdSeconds}: segundos aguantando (planchas); nulo si son repeticiones.
     * {@code repMin}-{@code repMax}: rango de repeticiones; {@code repsInReserve}: cuántas deben sobrar en cada serie.
     * Nulos si el ejercicio no tiene rango (movilidad, aguantes).
     */
    public record Item(UUID exerciseId, int sets, int reps, int restSeconds, Integer holdSeconds, Integer repMin,
                       Integer repMax, Integer repsInReserve) {
        public Item {
            Objects.requireNonNull(exerciseId, "exerciseId");
        }

        public Item(UUID exerciseId, int sets, int reps, int restSeconds, Integer holdSeconds) {
            this(exerciseId, sets, reps, restSeconds, holdSeconds, null, null, null);
        }

        /** Rango de repeticiones del ejercicio; nulo sin rango o si es un aguante. */
        public RepRange repRange() {
            return holdSeconds != null ? null : RepRange.of(repMin, repMax, repsInReserve);
        }
    }

    /**
     * Día de la semana para salir a correr con el entreno de carrera {@code workoutCode} (de
     * {@code RunWorkoutTemplates}); {@code workoutName} es su nombre en el idioma pedido. {@code week}: semana del
     * plan en la que toca (1..semanas) o 0 si se repite todas.
     */
    public record RunDay(int dayNumber, String workoutCode, String workoutName, int week) {
        public RunDay {
            Guard.range(dayNumber, "dayNumber", 1, 7);
            Guard.range(week, "week", 0, 12);
            Objects.requireNonNull(workoutCode, "workoutCode");
        }

        public RunDay(int dayNumber, String workoutCode, String workoutName) {
            this(dayNumber, workoutCode, workoutName, 0);
        }
    }

    public RoutineTemplate(UUID id, String code, String name, String description, TrainingGoal goal,
                           TemplatePlace place, TemplateLevel level, boolean forExams, int minutes, int weeks,
                           List<Day> days, List<RunDay> runDays) {
        this(id, code, name, description, goal, place, level, forExams, minutes, weeks, days, runDays, true);
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

    /** Días de la semana distintos en los que se sale a correr (un plan progresivo cambia la salida, no el día). */
    public List<Integer> runWeekdays() {
        return runDays.stream().map(RunDay::dayNumber).distinct().sorted().toList();
    }

    /** Días que se entrena cada semana, contando los de carrera. */
    public int daysPerWeek() {
        return days.size() + runWeekdays().size();
    }

    /** Entrenos de carrera distintos que pide la plantilla, por semana y día. */
    public List<RunDay> distinctRunWorkouts() {
        Map<String, RunDay> byCode = new LinkedHashMap<>();
        runDays.stream().sorted(Comparator.comparingInt(RunDay::week).thenComparingInt(RunDay::dayNumber))
                .forEach(d -> byCode.putIfAbsent(d.workoutCode(), d));
        return List.copyOf(byCode.values());
    }

    /** Ejercicios distintos de la plantilla. */
    public List<UUID> exerciseIds() {
        return days.stream().flatMap(d -> d.exercises().stream()).map(Item::exerciseId).distinct().toList();
    }

    /** Parámetros de un ejercicio en una semana del tipo dado (la suave quita una serie). */
    public static ExerciseParameters parametersFor(Item item, WeekType type) {
        return parametersFor(item, type, null);
    }

    /**
     * Parámetros de un ejercicio en una semana del tipo dado, con su peso de partida (nulo sin peso). La suave quita
     * una serie; con rango, se empieza por el mínimo (doble progresión).
     */
    public static ExerciseParameters parametersFor(Item item, WeekType type, Double weightKg) {
        int sets = type == WeekType.DELOAD ? Math.max(1, item.sets() - 1) : item.sets();
        RepRange range = item.repRange();
        int reps = range == null ? item.reps() : range.min();
        return ExerciseParameters.clamped(sets, reps, item.restSeconds(), weightKg, null, null, null,
                item.holdSeconds()).withRepRange(range);
    }
}
