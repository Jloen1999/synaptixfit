package com.synaptixfit.application.port.input.badge;

import com.synaptixfit.domain.model.badge.StreakStatus;
import java.util.UUID;

/** La racha de hoy, con sus pausas, sin guardarla en la cuenta: para lecturas como el catálogo de insignias. */
public interface PeekStreakUseCase {

    StreakStatus peekStreak(UUID userId, String zone);
}
