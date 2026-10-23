package com.synaptixfit.infrastructure.adapter.input.rest.planner.dto;

/** Resultado de guardar el plan: bloques y entregas asociados y experiencia dada ahora (0 si ya se dio). */
public record SavePlanResponse(StudyPlanResponse plan, int blockCount, int deadlineCount, int xpAwarded) {
}
