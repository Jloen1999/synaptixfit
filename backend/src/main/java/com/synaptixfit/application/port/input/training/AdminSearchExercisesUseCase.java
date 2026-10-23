package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import com.synaptixfit.domain.model.training.Exercise;
import com.synaptixfit.domain.model.training.ExerciseSearchCriteria;

/** Búsqueda de administración (incluye ejercicios inactivos). */
public interface AdminSearchExercisesUseCase {

    PageResult<Exercise> adminSearch(ExerciseSearchCriteria criteria, PageRequest page);
}
