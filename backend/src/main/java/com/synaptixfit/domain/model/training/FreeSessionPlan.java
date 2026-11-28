package com.synaptixfit.domain.model.training;

import com.synaptixfit.domain.model.training.TrainingSession.FreeExercise;
import com.synaptixfit.domain.model.training.generation.LoadSuggestions;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * Reglas de la lista de ejercicios de una sesión libre (ADR 0067): las cifras de partida de un ejercicio elegido y la
 * lista que sale de lo que se hizo en una sesión, para «Repetir un entreno» y para «Guardar como rutina».
 */
public final class FreeSessionPlan {

    private FreeSessionPlan() {
    }

    /**
     * Cifras de partida de un ejercicio elegido a mano, según cómo se mide (las mismas que al añadirlo a una rutina):
     * cardio, un bloque de 10 min; aguante (plancha), 3 × 30 s; movilidad, 2 × 10; el resto, 3 × 10 con 90 s de
     * descanso. {@code weightKg}: el peso de partida «para probar» (nulo si no lleva).
     */
    public static ExerciseParameters startingFor(ExerciseRef exercise, Double weightKg) {
        boolean timed = exercise.measurementTypes().contains(MeasurementType.TIME)
                && !exercise.measurementTypes().contains(MeasurementType.REPETITIONS);
        if (exercise.modality() == Modality.AEROBIC) {
            return ExerciseParameters.clamped(1, 1, 60, null, null, 600, null, null);
        }
        if (timed) {
            return ExerciseParameters.clamped(3, 1, 60, null, null, null, null, 30);
        }
        if (exercise.modality() == Modality.MOBILITY) {
            return ExerciseParameters.clamped(2, 10, 30, null, null, null, null, null);
        }
        return ExerciseParameters.clamped(3, 10, 90, weightKg, null, null, null, null);
    }

    /**
     * Lo que se hizo en una sesión, ejercicio a ejercicio y en el orden de su lista: tantas series como se apuntaron
     * y las cifras de verdad (la serie de más peso, el aguante más largo…, como la propuesta de carga). Las series sin
     * ejercicio (sesiones libres antiguas) no entran. {@code slots} son los huecos de la sesión (su día de rutina o
     * su lista libre) y {@code refs} resuelve un ejercicio cambiado «solo hoy» que no está en ellos.
     */
    public static List<FreeExercise> performed(List<PlannedExercise> slots, List<SessionSet> workSets,
                                               Function<UUID, Optional<ExerciseRef>> refs) {
        Map<UUID, PlannedExercise> slotById = slots.stream()
                .collect(Collectors.toMap(PlannedExercise::id, Function.identity(), (a, b) -> a));
        Map<UUID, List<SessionSet>> byExercise = new LinkedHashMap<>();
        workSets.stream().filter(s -> s.exerciseId() != null)
                .sorted(Comparator.comparingInt((SessionSet s) -> orderOf(slotById.get(s.plannedExerciseId())))
                        .thenComparingInt(SessionSet::setNumber))
                .forEach(s -> byExercise.computeIfAbsent(s.exerciseId(), k -> new ArrayList<>()).add(s));
        List<FreeExercise> result = new ArrayList<>();
        byExercise.forEach((exerciseId, sets) -> {
            PlannedExercise slot = slotById.get(sets.getFirst().plannedExerciseId());
            Optional<ExerciseRef> ref = slot != null && slot.exerciseId().equals(exerciseId)
                    ? Optional.of(slot.exercise()) : refs.apply(exerciseId);
            ref.ifPresent(r -> result.add(new FreeExercise(r, parametersOf(r, slot, sets))));
        });
        return result;
    }

    private static ExerciseParameters parametersOf(ExerciseRef exercise, PlannedExercise slot, List<SessionSet> sets) {
        ExerciseParameters plan = slot != null && slot.exerciseId().equals(exercise.id())
                ? slot.parameters() : startingFor(exercise, null);
        ExerciseParameters done = LoadSuggestions.performed(plan, exercise.measurementTypes(), sets);
        int count = (int) sets.stream().map(SessionSet::setNumber).distinct().count();
        return ExerciseParameters.clamped(count, done.reps(), done.restSeconds(), done.weightKg(), null,
                done.targetDurationSeconds(), done.distanceMeters(), done.isometricSeconds())
                .withRepRange(done.repRange());
    }

    private static int orderOf(PlannedExercise slot) {
        return Objects.isNull(slot) ? Integer.MAX_VALUE : slot.order();
    }
}
