package com.synaptixfit.application.port.input.planner;

import com.synaptixfit.domain.model.planner.StudyPlan;
import com.synaptixfit.domain.model.shared.Visibility;
import java.time.LocalDate;
import java.util.UUID;

/**
 * Guarda el plan de la semana (ruta de las apps anteriores al ADR 0038): reutiliza el plan de esa semana (o lo
 * crea) y le asocia sus bloques y entregas. La experiencia sigue la misma regla que sin botón
 * ({@code StudyPlan.rewardable}): una vez por semana y con suficientes eventos planificados.
 */
public interface SaveWeeklyPlanUseCase {

    /** @param name nombre del plan (nulo: «Plan d/M» al crearlo; se conserva al reutilizarlo) */
    record Command(UUID userId, LocalDate weekStart, String name, Visibility visibility) {
    }

    /** @param xpAwarded experiencia dada en esta operación (0 si ya se dio antes) */
    record Result(StudyPlan plan, int blockCount, int deadlineCount, int xpAwarded) {
    }

    Result savePlan(Command command);
}
