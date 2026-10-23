package com.synaptixfit.application.port.input.planner;

import com.synaptixfit.domain.model.planner.StudyPlan;
import com.synaptixfit.domain.model.shared.Visibility;
import java.time.LocalDate;
import java.util.UUID;

/**
 * Guarda el plan de la semana: reutiliza el plan existente de esa semana (o lo crea), le asocia los
 * bloques y entregas de la semana y, la primera vez, da {@code 100 + 5 × nº de bloques} de experiencia.
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
