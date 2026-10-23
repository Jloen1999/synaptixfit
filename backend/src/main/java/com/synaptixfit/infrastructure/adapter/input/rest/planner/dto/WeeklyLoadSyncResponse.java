package com.synaptixfit.infrastructure.adapter.input.rest.planner.dto;

/** Carga recalculada y experiencia semanal de estudio dada en esta operación. */
public record WeeklyLoadSyncResponse(WeeklyLoadResponse load, int xpAwarded) {
}
