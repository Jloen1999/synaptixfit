package com.synaptixfit.application.port.input.analytics;

import com.synaptixfit.domain.model.analytics.RpeTrend;
import java.util.UUID;

/** Tendencia del RPE medio semanal en el periodo. */
public interface GetRpeTrendUseCase {

    RpeTrend getRpeTrend(UUID userId, String period);
}
