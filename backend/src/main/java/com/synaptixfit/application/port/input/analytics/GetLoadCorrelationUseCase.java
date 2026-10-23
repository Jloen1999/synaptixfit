package com.synaptixfit.application.port.input.analytics;

import com.synaptixfit.domain.model.analytics.LoadCorrelation;
import java.util.UUID;

/** Correlación de Pearson entre horas de estudio semanales y entrenamiento (últimas 52 semanas). */
public interface GetLoadCorrelationUseCase {

    /** @param metric RPE o MINUTES (null: RPE) */
    LoadCorrelation getLoadCorrelation(UUID userId, String metric);
}
