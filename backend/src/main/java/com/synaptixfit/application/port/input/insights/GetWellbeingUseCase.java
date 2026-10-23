package com.synaptixfit.application.port.input.insights;

import com.synaptixfit.domain.model.insights.WellbeingSnapshot;
import java.util.UUID;

/** Estado energético, adherencia académica y factor de carga total de hoy. */
public interface GetWellbeingUseCase {

    WellbeingSnapshot getWellbeing(UUID userId, String timeZone);
}
