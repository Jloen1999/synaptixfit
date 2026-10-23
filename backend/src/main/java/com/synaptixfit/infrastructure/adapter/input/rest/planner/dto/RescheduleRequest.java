package com.synaptixfit.infrastructure.adapter.input.rest.planner.dto;

import java.time.Instant;

/** Nuevo horario: solo {@code start} mueve conservando la duración; solo {@code end} redimensiona. */
public record RescheduleRequest(Instant start, Instant end) {
}
