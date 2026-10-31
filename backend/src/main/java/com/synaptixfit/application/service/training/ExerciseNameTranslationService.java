package com.synaptixfit.application.service.training;

import com.synaptixfit.application.port.input.training.GetExerciseNamesUseCase;
import com.synaptixfit.application.port.input.training.SuggestExerciseNamesUseCase;
import com.synaptixfit.domain.exception.training.ExerciseNotFoundException;
import com.synaptixfit.domain.model.shared.Guard;
import com.synaptixfit.domain.model.training.ExerciseNameTranslations;
import com.synaptixfit.domain.port.output.training.ExerciseNameTranslationsRepositoryPort;
import com.synaptixfit.domain.port.output.training.ExerciseNameTranslatorPort;
import com.synaptixfit.domain.port.output.training.ExerciseRepositoryPort;
import java.util.UUID;

/**
 * Implementa {@link SuggestExerciseNamesUseCase} con {@link ExerciseNameTranslatorPort} (IA) y
 * {@link GetExerciseNamesUseCase} con {@link ExerciseNameTranslationsRepositoryPort}. Lo que propone la
 * IA no se guarda: la administración lo revisa y lo envía al crear o editar el ejercicio.
 */
public class ExerciseNameTranslationService implements SuggestExerciseNamesUseCase, GetExerciseNamesUseCase {

    private final ExerciseRepositoryPort exercises;
    private final ExerciseNameTranslationsRepositoryPort names;
    private final ExerciseNameTranslatorPort translator;

    public ExerciseNameTranslationService(ExerciseRepositoryPort exercises, ExerciseNameTranslationsRepositoryPort names,
                                          ExerciseNameTranslatorPort translator) {
        this.exercises = exercises;
        this.names = names;
        this.translator = translator;
    }

    @Override
    public ExerciseNameTranslations suggest(String spanishName) {
        // Mismos límites que el nombre del ejercicio.
        return translator.suggest(Guard.length(spanishName, "name", 2, 200));
    }

    @Override
    public ExerciseNameTranslations names(UUID exerciseId) {
        if (exercises.findById(exerciseId).isEmpty()) {
            throw new ExerciseNotFoundException(exerciseId);
        }
        return names.findByExercise(exerciseId);
    }
}
