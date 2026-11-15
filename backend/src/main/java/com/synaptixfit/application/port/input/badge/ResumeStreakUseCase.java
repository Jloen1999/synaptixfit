package com.synaptixfit.application.port.input.badge;

import com.synaptixfit.domain.model.badge.StreakStatus;
import java.util.UUID;

/** «Reanudar» la racha en pausa (ADR 0042): la pausa acaba ayer. Sin pausa en curso no hace nada (idempotente). */
public interface ResumeStreakUseCase {

    StreakStatus resume(UUID userId, String zone);
}
