package com.synaptixfit.application.service.training;

import com.synaptixfit.application.port.input.training.GetExerciseNoteUseCase;
import com.synaptixfit.application.port.input.training.GetExerciseTipsUseCase;
import com.synaptixfit.application.port.input.training.SaveExerciseNoteUseCase;
import com.synaptixfit.domain.exception.training.ExerciseNotFoundException;
import com.synaptixfit.domain.model.training.Exercise;
import com.synaptixfit.domain.model.training.ExerciseNote;
import com.synaptixfit.domain.model.training.ExerciseTips;
import com.synaptixfit.domain.port.output.training.ExerciseNoteRepositoryPort;
import com.synaptixfit.domain.port.output.training.ExerciseRepositoryPort;
import com.synaptixfit.domain.port.output.training.ExerciseTipsRepositoryPort;
import java.time.Clock;
import java.util.Optional;
import java.util.UUID;

/**
 * Guía de un ejercicio (ADR 0031): sus consejos del catálogo y la nota propia de cada persona. Usa
 * {@link ExerciseTipsRepositoryPort} y {@link ExerciseNoteRepositoryPort}; solo con ejercicios activos.
 */
public class ExerciseGuideService implements GetExerciseTipsUseCase, GetExerciseNoteUseCase, SaveExerciseNoteUseCase {

    /** Idioma canónico del catálogo: si no hay consejos en el pedido, se enseñan en este. */
    static final String FALLBACK_LANGUAGE = "es";

    private final ExerciseRepositoryPort exercises;
    private final ExerciseTipsRepositoryPort tips;
    private final ExerciseNoteRepositoryPort notes;
    private final Clock clock;

    public ExerciseGuideService(ExerciseRepositoryPort exercises, ExerciseTipsRepositoryPort tips,
                                ExerciseNoteRepositoryPort notes, Clock clock) {
        this.exercises = exercises;
        this.tips = tips;
        this.notes = notes;
        this.clock = clock;
    }

    @Override
    public ExerciseTips tips(UUID exerciseId, String language) {
        active(exerciseId);
        String lang = language == null || language.isBlank() ? FALLBACK_LANGUAGE : language;
        return tips.find(exerciseId, lang)
                .or(() -> lang.equals(FALLBACK_LANGUAGE) ? Optional.empty() : tips.find(exerciseId, FALLBACK_LANGUAGE))
                .orElse(ExerciseTips.EMPTY);
    }

    @Override
    public Optional<ExerciseNote> note(UUID userId, UUID exerciseId) {
        return notes.find(userId, exerciseId);
    }

    @Override
    public Optional<ExerciseNote> save(UUID userId, UUID exerciseId, String text) {
        active(exerciseId);
        if (text == null || text.isBlank()) {
            notes.delete(userId, exerciseId);
            return Optional.empty();
        }
        ExerciseNote note = new ExerciseNote(exerciseId, text, clock.instant());
        notes.save(userId, note);
        return Optional.of(note);
    }

    private Exercise active(UUID exerciseId) {
        return exercises.findById(exerciseId).filter(Exercise::active)
                .orElseThrow(() -> new ExerciseNotFoundException(exerciseId));
    }
}
