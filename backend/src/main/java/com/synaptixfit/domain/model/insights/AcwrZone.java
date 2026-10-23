package com.synaptixfit.domain.model.insights;

/**
 * Zona de riesgo según el ACWR (Gabbett, 2016).
 *
 * <ul>
 *   <li>NO_DATA: sin carga en los últimos 28 días.</li>
 *   <li>UNDERTRAINING: ACWR &lt; 0.8 (desentrenamiento relativo).</li>
 *   <li>OPTIMAL: 0.8 ≤ ACWR ≤ 1.3 (zona óptima).</li>
 *   <li>DANGER: 1.3 &lt; ACWR ≤ 1.5 (riesgo creciente; empieza la penalización del estudio).</li>
 *   <li>OVERTRAINING: ACWR &gt; 1.5 (riesgo alto de lesión y fatiga).</li>
 * </ul>
 */
public enum AcwrZone {
    NO_DATA,
    UNDERTRAINING,
    OPTIMAL,
    DANGER,
    OVERTRAINING;

    public static AcwrZone of(Double acwr) {
        if (acwr == null) {
            return NO_DATA;
        }
        if (acwr < 0.8) {
            return UNDERTRAINING;
        }
        if (acwr <= 1.3) {
            return OPTIMAL;
        }
        return acwr <= 1.5 ? DANGER : OVERTRAINING;
    }

    public boolean isRisky() {
        return this == DANGER || this == OVERTRAINING;
    }
}
