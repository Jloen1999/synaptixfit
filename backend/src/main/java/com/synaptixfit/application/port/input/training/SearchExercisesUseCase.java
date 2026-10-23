package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import com.synaptixfit.domain.model.training.Exercise;
import com.synaptixfit.domain.model.training.ExerciseSearchCriteria;

/** Busca en el catálogo de ejercicios activos con filtros y paginación. */
public interface SearchExercisesUseCase {

    PageResult<Exercise> search(ExerciseSearchCriteria criteria, PageRequest page);
}
