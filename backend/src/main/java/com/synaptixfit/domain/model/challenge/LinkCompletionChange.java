package com.synaptixfit.domain.model.challenge;

/** Cambio de estado de un reto o tarea vinculados a un examen o entrega. */
public record LinkCompletionChange(ChallengeLink link, boolean completed) {
}
