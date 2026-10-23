package com.synaptixfit.application.port.input.challenge;

import com.synaptixfit.domain.model.challenge.ChallengeSummary;
import java.util.UUID;

/** Recuento de retos activos, completados y vencidos del usuario. */
public interface GetChallengeSummaryUseCase {

    ChallengeSummary getChallengeSummary(UUID userId);
}
