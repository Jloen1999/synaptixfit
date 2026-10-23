package com.synaptixfit.application.port.input.challenge;

import com.synaptixfit.domain.model.challenge.ProgressEntry;
import java.util.List;
import java.util.UUID;

/** Historial de progreso manual de un reto propio. */
public interface ListChallengeProgressUseCase {

    List<ProgressEntry> listProgress(UUID userId, UUID challengeId);
}
