package com.synaptixfit.application.port.input.academic;

import com.synaptixfit.domain.model.academic.PracticeResult;
import java.util.Map;
import java.util.UUID;

/** Corrige una práctica libre de todo el banco y concede su XP una sola vez por banco. */
public interface CompleteBankPracticeUseCase {

    PracticeResult completePractice(UUID userId, UUID bankId, Map<UUID, String> answers);
}
