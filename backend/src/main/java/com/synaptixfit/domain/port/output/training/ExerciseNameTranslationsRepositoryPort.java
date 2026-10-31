package com.synaptixfit.domain.port.output.training;

import com.synaptixfit.domain.model.training.ExerciseNameTranslations;
import java.util.UUID;

/** Nombres de un ejercicio en otros idiomas, para que la administración los vea y los cambie. */
public interface ExerciseNameTranslationsRepositoryPort {

    ExerciseNameTranslations findByExercise(UUID exerciseId);

    /** Deja exactamente estos nombres: un idioma vacío se borra (y se muestra en español). */
    void replace(UUID exerciseId, ExerciseNameTranslations names);
}
