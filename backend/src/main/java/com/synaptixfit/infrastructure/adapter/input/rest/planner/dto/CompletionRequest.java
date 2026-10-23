package com.synaptixfit.infrastructure.adapter.input.rest.planner.dto;

import jakarta.validation.constraints.NotNull;

/** Marcar ({@code true}) o desmarcar ({@code false}) como completado. */
public record CompletionRequest(@NotNull Boolean completed) {
}
