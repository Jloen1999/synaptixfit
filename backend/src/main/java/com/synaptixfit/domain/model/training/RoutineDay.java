package com.synaptixfit.domain.model.training;

import com.synaptixfit.domain.exception.training.RoutineExerciseNotFoundException;
import com.synaptixfit.domain.exception.training.RoutineReorderMismatchException;
import com.synaptixfit.domain.model.shared.Guard;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashSet;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.UUID;

/** Día de una semana de rutina (número 1-7) con sus ejercicios ordenados. */
public final class RoutineDay {

    private final UUID id;
    private final int number;
    private String name;
    private ProgressStatus status;
    private final List<PlannedExercise> exercises;

    public RoutineDay(UUID id, int number, String name, ProgressStatus status, List<PlannedExercise> exercises) {
        this.id = Objects.requireNonNull(id, "id");
        this.number = Guard.range(number, "dayNumber", 1, 7);
        this.name = normalizeName(name, number);
        this.status = status == null ? ProgressStatus.PENDING : status;
        this.exercises = new ArrayList<>(exercises == null ? List.of() : exercises);
        this.exercises.sort(Comparator.comparingInt(PlannedExercise::order));
    }

    public static RoutineDay create(int number, String name) {
        return new RoutineDay(UUID.randomUUID(), number, name, ProgressStatus.PENDING, List.of());
    }

    private static String normalizeName(String name, int number) {
        if (name == null || name.isBlank()) {
            return "Día " + number;
        }
        return Guard.length(name, "dayName", 1, 120);
    }

    public void rename(String newName) {
        this.name = normalizeName(newName, number);
    }

    public PlannedExercise addExercise(ExerciseRef exercise, ExerciseParameters parameters) {
        PlannedExercise planned = new PlannedExercise(UUID.randomUUID(), exercise, parameters,
                exercises.size() + 1, null);
        exercises.add(planned);
        return planned;
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

    /** Se ha empezado una sesión de este día. Un día completado no retrocede. */
    public void markInProgress() {
        if (status != ProgressStatus.COMPLETED) {
            status = ProgressStatus.IN_PROGRESS;
        }
    }

    public void markCompleted() {
        status = ProgressStatus.COMPLETED;
    }

    public void markPending() {
        status = ProgressStatus.PENDING;
    }

    public boolean isEmpty() {
        return exercises.isEmpty();
    }

    RoutineDay copyReset() {
        return new RoutineDay(UUID.randomUUID(), number, name, ProgressStatus.PENDING,
                exercises.stream().map(PlannedExercise::copyWithNewId).toList());
    }

    public UUID id() { return id; }
    public int number() { return number; }
    public String name() { return name; }
    public ProgressStatus status() { return status; }
    public List<PlannedExercise> exercises() { return List.copyOf(exercises); }
}
