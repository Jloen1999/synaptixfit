package com.synaptixfit.application.port.input.analytics;

import com.synaptixfit.domain.model.analytics.Insight;
import java.util.List;
import java.util.UUID;

/** Interpretaciones estructuradas (racha, constancia, volumen y correlación) del periodo. */
public interface GetAnalyticsInsightsUseCase {

    List<Insight> getAnalyticsInsights(UUID userId, String period);
}
