package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.training.MediaCredit;
import java.util.List;
import java.util.UUID;

/** Quién hizo la foto y el vídeo de un ejercicio del catálogo y con qué licencia (ADR 0056). */
public interface ListExerciseMediaCreditsUseCase {

    List<MediaCredit> mediaCredits(UUID exerciseId);
}
