package com.synaptixfit.domain.model.challenge;

import java.time.Instant;
import java.util.UUID;

/** Registro manual de progreso de un reto o de una de sus tareas ({@code progreso_de_reto}). */
public record ProgressEntry(UUID id, UUID challengeId, UUID milestoneId, UUID userId, double amount,
                            Instant recordedAt, Instant createdAt) {
}
