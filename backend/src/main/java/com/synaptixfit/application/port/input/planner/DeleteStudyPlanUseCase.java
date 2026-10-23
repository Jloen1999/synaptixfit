package com.synaptixfit.application.port.input.planner;

import java.util.UUID;

/** Borra un plan semanal (sus bloques y entregas se conservan, desvinculados). */
public interface DeleteStudyPlanUseCase {

    void deletePlan(UUID userId, UUID planId);
}
