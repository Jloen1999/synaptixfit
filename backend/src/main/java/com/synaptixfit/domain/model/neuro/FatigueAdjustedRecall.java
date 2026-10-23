package com.synaptixfit.domain.model.neuro;

/**
 * Fórmula 4 (SM-2-Physio): calidad de recuerdo ajustada por la fatiga física del día.
 *
 * <p>{@code Q_adj = Q_real + eta * (carga_hoy / carga_max_historica)}, con eta = 0.5, acotado a
 * [0, 5] y sin redondear (la fracción decimal entra en el factor de facilidad del SM-2).
 */
public final class FatigueAdjustedRecall {

    static final double ETA = 0.5;

    private FatigueAdjustedRecall() {
    }

    public static double adjustedQuality(int realQuality, double loadToday, double maxDailyLoad) {
        if (maxDailyLoad <= 0) {
            return realQuality;
        }
        double ratio = Math.max(0, Math.min(1, loadToday / maxDailyLoad));
        return Math.max(0, Math.min(5, realQuality + ETA * ratio));
    }

    /** Coeficiente de fatiga aplicado (para auditoría): eta * ratio. */
    public static double fatigueCoefficient(double loadToday, double maxDailyLoad) {
        if (maxDailyLoad <= 0) {
            return 0;
        }
        return ETA * Math.max(0, Math.min(1, loadToday / maxDailyLoad));
    }
}
