package com.synaptixfit.application.port.input.academic;

import com.synaptixfit.domain.model.academic.RetentionMetrics;
import java.util.UUID;

/** Métricas de retención (materiales por estado de dominio) de una asignatura propia. */
public interface GetRetentionMetricsUseCase {

    RetentionMetrics retention(UUID userId, UUID subjectId);
}
