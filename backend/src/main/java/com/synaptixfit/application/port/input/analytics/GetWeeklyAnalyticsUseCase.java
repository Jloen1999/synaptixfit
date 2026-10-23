package com.synaptixfit.application.port.input.analytics;

import com.synaptixfit.domain.model.analytics.WeeklyAnalytics;
import java.util.UUID;

/** Serie semanal de entrenamiento (sesiones, RPE medio, minutos, calorías) del periodo. */
public interface GetWeeklyAnalyticsUseCase {

    /** @param period WEEKLY, MONTHLY o QUARTERLY (null: MONTHLY) */
    WeeklyAnalytics getWeeklyAnalytics(UUID userId, String period);
}
