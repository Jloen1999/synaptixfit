package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.training.CycleOverview;
import java.util.UUID;

/**
 * Activa (con consentimiento explícito) o desactiva el seguimiento del ciclo. Al desactivarlo se puede pedir que
 * se borre todo lo apuntado.
 */
public interface ChangeCycleTrackingUseCase {

    CycleOverview change(UUID userId, boolean enabled, boolean consent, boolean deleteHistory);
}
