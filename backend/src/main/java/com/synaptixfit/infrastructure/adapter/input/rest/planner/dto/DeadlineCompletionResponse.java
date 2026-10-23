package com.synaptixfit.infrastructure.adapter.input.rest.planner.dto;

/** Entrega tras marcar/desmarcar y experiencia sumada o restada. */
public record DeadlineCompletionResponse(DeadlineResponse deadline, int xpDelta) {
}
