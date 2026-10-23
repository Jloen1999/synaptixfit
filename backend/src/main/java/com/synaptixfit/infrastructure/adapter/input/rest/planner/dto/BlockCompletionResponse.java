package com.synaptixfit.infrastructure.adapter.input.rest.planner.dto;

/** Bloque tras marcar/desmarcar y experiencia sumada (positiva) o restada (negativa). */
public record BlockCompletionResponse(CalendarBlockResponse block, int xpDelta) {
}
