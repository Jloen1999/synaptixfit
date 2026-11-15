package com.synaptixfit.domain.port.output.badge;

import com.synaptixfit.domain.model.badge.StreakPause;
import java.util.List;
import java.util.UUID;

/** Pausas de racha del usuario (tabla {@code pausas_racha}, ADR 0042). */
public interface StreakPauseRepositoryPort {

    /** Todas las pausas del usuario (son pocas: como mucho unas pocas al trimestre). */
    List<StreakPause> findByUser(UUID userId);

    StreakPause save(StreakPause pause);

    void delete(UUID id);
}
