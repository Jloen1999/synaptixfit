package com.synaptixfit.domain.model.training;

/**
 * Momento estimado del ciclo, con nombres cotidianos en el cliente: «Con la regla», «Después de la regla»,
 * «Mitad del ciclo» y «Días antes de la regla». Es una estimación a partir de los días apuntados (ver
 * {@link CycleOverview}), no un dato médico.
 */
public enum CyclePhase {
    PERIOD,
    AFTER_PERIOD,
    MID_CYCLE,
    BEFORE_PERIOD
}
