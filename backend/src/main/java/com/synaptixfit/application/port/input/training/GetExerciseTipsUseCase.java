package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.training.ExerciseTips;
import java.util.UUID;

/** «Las claves» y «Errores comunes» de un ejercicio del catálogo en el idioma pedido (o en español). */
public interface GetExerciseTipsUseCase {

    ExerciseTips tips(UUID exerciseId, String language);
}
