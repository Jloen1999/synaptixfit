package com.synaptixfit.domain.model.challenge;

/** Tarea disponible o en curso de un reto activo (para la agenda del día). */
public record PendingMilestone(Challenge challenge, Milestone milestone) {
}
