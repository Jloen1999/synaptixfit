package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.training.OpenTrainingSession;
import java.util.List;
import java.util.UUID;

/** Sesiones sin terminar del usuario (en curso y abandonadas) con el nombre de su rutina y día. */
public interface ListOpenSessionsUseCase {

    List<OpenTrainingSession> listOpen(UUID userId);
}
