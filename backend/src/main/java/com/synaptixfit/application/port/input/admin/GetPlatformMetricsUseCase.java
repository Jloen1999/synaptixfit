package com.synaptixfit.application.port.input.admin;

import com.synaptixfit.domain.model.admin.PlatformMetrics;

/** Indicadores globales de la plataforma. */
public interface GetPlatformMetricsUseCase {

    PlatformMetrics getPlatformMetrics();
}
