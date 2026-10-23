package com.synaptixfit.application.port.input.insights;

import com.synaptixfit.domain.model.insights.PhysicalLoadSummary;
import java.util.UUID;

/** Carga física de hoy, máxima diaria histórica y serie de los últimos 28 días. */
public interface GetPhysicalLoadUseCase {

    PhysicalLoadSummary getPhysicalLoad(UUID userId, String timeZone);
}
