package com.synaptixfit.application.port.input.profile;

import com.synaptixfit.domain.model.profile.GoalHistoryEntry;
import java.util.List;
import java.util.UUID;

/** Historial de objetivos principales del usuario (más reciente primero). */
public interface GetGoalHistoryUseCase {

    List<GoalHistoryEntry> getGoalHistory(UUID userId);
}
