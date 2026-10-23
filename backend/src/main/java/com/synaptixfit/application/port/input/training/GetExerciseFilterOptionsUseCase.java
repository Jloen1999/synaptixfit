package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.training.ExerciseFilterOptions;

/** Músculos, partes del cuerpo y equipamientos para filtrar el catálogo. */
public interface GetExerciseFilterOptionsUseCase {

    ExerciseFilterOptions filterOptions();
}
