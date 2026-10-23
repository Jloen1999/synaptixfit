package com.synaptixfit.infrastructure.adapter.input.rest.challenge.dto;

import com.synaptixfit.domain.model.challenge.ProgressEntry;
import java.time.Instant;
import java.util.UUID;

/** Registro de progreso manual ({@code milestoneId} nulo = progreso del reto sin tareas). */
public record ProgressEntryResponse(UUID id, UUID milestoneId, double amount, Instant recordedAt, Instant createdAt) {

    public static ProgressEntryResponse from(ProgressEntry p) {
        return new ProgressEntryResponse(p.id(), p.milestoneId(), p.amount(), p.recordedAt(), p.createdAt());
    }
}
