package com.synaptixfit.domain.port.output.planner;

import com.synaptixfit.domain.model.planner.PlannerZone;
import com.synaptixfit.domain.model.planner.PlanningInbox;
import com.synaptixfit.domain.model.planner.SuggestedBlock;
import java.util.List;

/**
 * Propone con IA los bloques de estudio y deporte de una semana. Lanza AiUnavailableException o
 * AiQuotaExceededException; el servicio recurre entonces al plan heurístico.
 */
public interface PlanningAssistantPort {

    List<SuggestedBlock> suggestWeek(PlanningInbox inbox, PlannerZone zone);
}
