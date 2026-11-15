package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.training.Routine;
import java.util.UUID;

/** «Copiar a mis rutinas» desde un enlace (ADR 0043): copia privada, sin progreso y sin datos del dueño. */
public interface CopySharedRoutineUseCase {

    Routine copySharedRoutine(UUID userId, String token);
}
