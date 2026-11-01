package com.synaptixfit.domain.model.training;

import com.synaptixfit.domain.exception.training.RoutineDayNotSkippableException;
import com.synaptixfit.domain.exception.training.RoutineExerciseNotFoundException;
import com.synaptixfit.domain.exception.training.RoutineReorderMismatchException;
import com.synaptixfit.domain.model.shared.Guard;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashSet;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.UUID;

/**
 * Día de una semana de rutina con sus ejercicios ordenados. El número (1-7) es el día de la semana
 * preferido (1 = lunes): la rutina avanza por orden, no por fechas, y ese número solo sirve para
 * proponer cuándo toca. Sin nombre propio el nombre es nulo y el cliente muestra el día de la semana.
 *
 * <p>{@code closedOn} es el día en que se completó o se saltó: marca el ritmo real de la rutina
 * (el próximo día se propone a partir de ahí, ver {@link RoutineSchedule}).
 */
public final class RoutineDay {

    private final UUID id;
    private final int number;
    private String name;
    private ProgressStatus status;
    private LocalDate closedOn;
    private final List<PlannedExercise> exercises;

    public RoutineDay(UUID id, int number, String name, ProgressStatus status, LocalDate closedOn,
                      List<PlannedExercise> exercises) {
        this.id = Objects.requireNonNull(id, "id");
        this.number = Guard.range(number, "dayNumber", 1, 7);
        this.name = normalizeName(name);
        this.status = status == null ? ProgressStatus.PENDING : status;
        this.closedOn = this.status.isClosed() ? closedOn : null;
        this.exercises = new ArrayList<>(exercises == null ? List.of() : exercises);
        this.exercises.sort(Comparator.comparingInt(PlannedExercise::order));
    }

    public RoutineDay(UUID id, int number, String name, ProgressStatus status, List<PlannedExercise> exercises) {
        this(id, number, name, status, null, exercises);
    }

    public static RoutineDay create(int number, String name) {
        return new RoutineDay(UUID.randomUUID(), number, name, ProgressStatus.PENDING, null, List.of());
    }

    private static String normalizeName(String name) {
        if (name == null || name.isBlank()) {
            return null;
        }
        return Guard.length(name.strip(), "dayName", 1, 120);
    }

    public void rename(String newName) {
        this.name = normalizeName(newName);
    }

    public PlannedExercise addExercise(ExerciseRef exercise, ExerciseParameters parameters) {
        PlannedExercise planned = new PlannedExercise(UUID.randomUUID(), exercise, parameters,
                exercises.size() + 1, null);
        exercises.add(planned);
        return planned;
    }

    /** Primer ejercicio del día: su foto representa el día (y la rutina, si es el que toca). */
    public Optional<ExerciseRef> coverExercise() {
        return exercises.stream().findFirst().map(PlannedExercise::exercise);
    }

    public Optional<PlannedExercise> findExercise(UUID plannedExerciseId) {
        return exercises.stream().filter(e -> e.id().equals(plannedExerciseId)).findFirst();
    }

    public void removeExercise(UUID plannedExerciseId) {
        PlannedExercise target = findExercise(plannedExerciseId)
                .orElseThrow(() -> new RoutineExerciseNotFoundException(plannedExerciseId));
        exercises.remove(target);
        renumber();
    }

    /**
     * Sustituye el ejercicio de un hueco por otro, en la misma posición y con los parámetros adaptados a
     * cómo se mide el nuevo. El hueco recibe un id nuevo, así que el antiguo deja de existir: las series ya
     * registradas conservan el ejercicio que se hizo de verdad porque cada serie guarda su propio
     * {@code exerciseId} (historial y récords no cambian de ejercicio).
     */
    public PlannedExercise replaceExercise(UUID plannedExerciseId, ExerciseRef replacement) {
        PlannedExercise target = findExercise(plannedExerciseId)
                .orElseThrow(() -> new RoutineExerciseNotFoundException(plannedExerciseId));
        PlannedExercise planned = new PlannedExercise(UUID.randomUUID(), replacement,
                target.parameters().adaptedTo(replacement), target.order(), null);
        exercises.set(exercises.indexOf(target), planned);
        return planned;
    }

    /** Reordena los ejercicios: la lista debe contener exactamente los ids actuales, sin repetir. */
    public void reorder(List<UUID> orderedIds) {
        if (orderedIds == null || orderedIds.size() != exercises.size()
                || !new HashSet<>(orderedIds).equals(new HashSet<>(exercises.stream().map(PlannedExercise::id).toList()))) {
            throw new RoutineReorderMismatchException();
        }
        exercises.sort(Comparator.comparingInt(e -> orderedIds.indexOf(e.id())));
        renumber();
    }

    private void renumber() {
        for (int i = 0; i < exercises.size(); i++) {
            exercises.get(i).changeOrder(i + 1);
        }
    }

    /** Se ha empezado una sesión de este día. Un día completado no retrocede; uno saltado se retoma. */
    public void markInProgress() {
        if (status != ProgressStatus.COMPLETED) {
            status = ProgressStatus.IN_PROGRESS;
            closedOn = null;
        }
    }

    /** Completado el día {@code on} (la fecha de la sesión, que puede ser anterior a hoy). */
    public void markCompleted(LocalDate on) {
        status = ProgressStatus.COMPLETED;
        closedOn = Objects.requireNonNull(on, "on");
    }

    /** Saltado el día {@code on}. Un día completado no se salta. */
    public void markSkipped(LocalDate on) {
        if (status == ProgressStatus.COMPLETED) {
            throw new RoutineDayNotSkippableException(id);
        }
        status = ProgressStatus.SKIPPED;
        closedOn = Objects.requireNonNull(on, "on");
    }

    public void markPending() {
        status = ProgressStatus.PENDING;
        closedOn = null;
    }

    /** Sin ejercicios no se puede entrenar: no se propone ni cuenta para cerrar la semana. */
    public boolean isTrainable() {
        return !exercises.isEmpty();
    }

    public boolean isEmpty() {
        return exercises.isEmpty();
    }

    RoutineDay copyReset() {
        return new RoutineDay(UUID.randomUUID(), number, name, ProgressStatus.PENDING, null,
                exercises.stream().map(PlannedExercise::copyWithNewId).toList());
    }

    public UUID id() { return id; }
    public int number() { return number; }
    public String name() { return name; }
    public ProgressStatus status() { return status; }
    public LocalDate closedOn() { return closedOn; }
    public List<PlannedExercise> exercises() { return List.copyOf(exercises); }

    /** Duración prevista del día en minutos ({@link SessionDurationEstimate}). */
    public int estimatedMinutes() { return SessionDurationEstimate.dayMinutes(exercises); }
}
