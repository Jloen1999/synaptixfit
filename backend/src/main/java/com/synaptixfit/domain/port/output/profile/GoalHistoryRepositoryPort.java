package com.synaptixfit.domain.port.output.profile;

import com.synaptixfit.domain.model.profile.GoalHistoryEntry;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/** Historial de objetivos principales. */
public interface GoalHistoryRepositoryPort {

    /** Periodo abierto más reciente del usuario. */
    Optional<GoalHistoryEntry> findOpen(UUID userId);

    GoalHistoryEntry save(GoalHistoryEntry entry);

    /** Periodos del usuario, del más reciente al más antiguo. */
    List<GoalHistoryEntry> findByUser(UUID userId);
}
