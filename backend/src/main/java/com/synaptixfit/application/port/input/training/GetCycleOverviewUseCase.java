package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.training.CycleOverview;
import java.util.UUID;

/** Resumen del seguimiento del ciclo: si está activo, el momento estimado y lo apuntado hoy. */
public interface GetCycleOverviewUseCase {

    CycleOverview overview(UUID userId);
}
