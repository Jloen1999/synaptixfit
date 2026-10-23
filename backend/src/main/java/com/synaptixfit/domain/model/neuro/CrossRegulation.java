package com.synaptixfit.domain.model.neuro;

/**
 * Fórmula 3: regulación cruzada entre carga académica y física.
 *
 * <p>A) El estrés académico reduce el volumen de entrenamiento:
 * {@code V_mod = V_base * (1 - lambda_s * min(1, (C/C_max) * e^(-sigma*D_examen)))}, con
 * sigma = 0.15 y lambda_s = 0.40; sin penalización a más de 60 días del examen.
 *
 * <p>B) La fatiga física acorta los bloques de estudio según el ACWR:
 * ACWR ≤ 1.3 → T_base; 1.3 &lt; ACWR ≤ 2.0 → {@code T_base * (1 - alpha*ln(ACWR/1.3))}; ACWR &gt; 2.0 →
 * T_base / 2; con alpha = 0.5 y un mínimo de 25 minutos.
 *
 * <p>ACWR (Gabbett, 2016): media diaria de carga de los últimos 7 días entre la media diaria de
 * los últimos 28. El sistema heredado dividía la suma de 7 días entre la media de 28 (un ratio
 * siete veces mayor); aquí se corrige.
 */
public final class CrossRegulation {

    static final double SIGMA = 0.15;
    static final double LAMBDA_S = 0.40;
    static final double ALPHA = 0.5;
    public static final int DEFAULT_STUDY_MINUTES = 90;
    public static final int MIN_STUDY_MINUTES = 25;

    private CrossRegulation() {
    }

    public static double modifiedVolume(double baseVolume, double cognitiveLoad, double maxLoad, int daysUntilExam) {
        if (daysUntilExam > 60 || maxLoad == 0) {
            return baseVolume;
        }
        double stress = Math.max(0, Math.min(1, cognitiveLoad / maxLoad));
        double urgency = Math.exp(-SIGMA * daysUntilExam);
        double penalty = LAMBDA_S * Math.max(0, Math.min(1, stress * urgency));
        return baseVolume * (1 - penalty);
    }

    public static int maxStudyMinutes(int baseMinutes, double acwr) {
        if (acwr <= 1.3) {
            return baseMinutes;
        }
        double value = acwr <= 2.0 ? baseMinutes * (1 - ALPHA * Math.log(acwr / 1.3)) : baseMinutes * 0.5;
        return (int) Math.max(Math.min(Math.round(value), baseMinutes), Math.min(MIN_STUDY_MINUTES, baseMinutes));
    }

    /**
     * ACWR a partir de las sumas de carga (RPE x minutos) de 7 y 28 días. Devuelve null si no hay
     * carga crónica (sin historial suficiente).
     */
    public static Double acwr(double acuteLoadSum7d, double chronicLoadSum28d) {
        double chronicDaily = chronicLoadSum28d / 28.0;
        if (chronicDaily <= 0) {
            return null;
        }
        return (acuteLoadSum7d / 7.0) / chronicDaily;
    }
}
