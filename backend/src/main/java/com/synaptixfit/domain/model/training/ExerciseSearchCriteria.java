package com.synaptixfit.domain.model.training;

/**
 * Filtros de búsqueda del catálogo. Los campos nulos no filtran. {@code text} usa búsqueda de texto
 * completo en español (con prefijos) sobre nombre y descripción.
 */
public record ExerciseSearchCriteria(String text, Integer bodyPartId, Integer muscleId, Integer equipmentId,
                                     Difficulty difficulty, Modality modality, TrainingGoal purpose,
                                     boolean includeInactive, ExerciseCategory category) {

    public ExerciseSearchCriteria(String text, Integer bodyPartId, Integer muscleId, Integer equipmentId,
                                  Difficulty difficulty, Modality modality, TrainingGoal purpose,
                                  boolean includeInactive) {
        this(text, bodyPartId, muscleId, equipmentId, difficulty, modality, purpose, includeInactive, null);
    }

    public static ExerciseSearchCriteria all() {
        return new ExerciseSearchCriteria(null, null, null, null, null, null, null, false);
    }
}
