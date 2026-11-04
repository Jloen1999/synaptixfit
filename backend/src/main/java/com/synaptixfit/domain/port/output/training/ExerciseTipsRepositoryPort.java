package com.synaptixfit.domain.port.output.training;

import com.synaptixfit.domain.model.training.ExerciseTips;
import java.util.Optional;
import java.util.UUID;

/** Consejos de cada ejercicio por idioma ({@code consejos_ejercicio}). */
public interface ExerciseTipsRepositoryPort {

    /** Los consejos guardados en ese idioma, o vacío si no hay. */
    Optional<ExerciseTips> find(UUID exerciseId, String language);
}
