package com.synaptixfit.domain.model.training;

import com.synaptixfit.domain.exception.FieldValidationException;
import com.synaptixfit.domain.model.shared.Guard;
import java.util.List;

/** Datos de alta o edición de un ejercicio del catálogo (administración). */
public record ExerciseDraft(String name, String description, List<String> instructions, Difficulty difficulty,
                            List<TrainingGoal> purposes, Modality modality, List<MeasurementType> measurementTypes,
                            boolean circuit, double met, String gifUrl, String previewUrl,
                            List<Integer> bodyPartIds, List<Integer> targetMuscleIds,
                            List<Integer> secondaryMuscleIds, List<Integer> equipmentIds) {

    public ExerciseDraft {
        name = Guard.length(name, "name", 2, 200);
        description = description == null || description.isBlank() ? null : description.strip();
        instructions = List.copyOf(instructions == null ? List.of() : instructions);
        if (instructions.size() > 30) {
            throw new FieldValidationException("instructions", "OUT_OF_RANGE", "at most 30 instructions");
        }
        difficulty = Guard.notNull(difficulty, "difficulty");
        modality = Guard.notNull(modality, "modality");
        purposes = List.copyOf(purposes == null || purposes.isEmpty() ? List.of(TrainingGoal.HYPERTROPHY) : purposes);
        measurementTypes = List.copyOf(measurementTypes == null || measurementTypes.isEmpty()
                ? List.of(MeasurementType.REPETITIONS) : measurementTypes);
        Guard.range(met, "met", 1.0, 25.0);
        bodyPartIds = List.copyOf(bodyPartIds == null ? List.of() : bodyPartIds);
        targetMuscleIds = List.copyOf(targetMuscleIds == null ? List.of() : targetMuscleIds);
        secondaryMuscleIds = List.copyOf(secondaryMuscleIds == null ? List.of() : secondaryMuscleIds);
        equipmentIds = List.copyOf(equipmentIds == null ? List.of() : equipmentIds);
    }
}
