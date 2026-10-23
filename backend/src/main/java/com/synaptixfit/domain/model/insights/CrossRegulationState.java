package com.synaptixfit.domain.model.insights;

import com.synaptixfit.domain.model.neuro.CrossRegulation;
import com.synaptixfit.domain.model.shared.Guard;
import java.time.Instant;
import java.util.UUID;

/**
 * Estado de regulación cruzada (caché de {@code estado_regulacion_cruzada}).
 *
 * <p>Criterio corregido: {@code acuteDailyLoad} y {@code chronicDailyLoad} son <b>medias diarias</b>
 * de carga (suma de 7 días / 7 y suma de 28 días / 28, ventanas que terminan hoy incluido), de modo
 * que su cociente es el ACWR de {@link CrossRegulation#acwr}. El sistema heredado guardaba la suma
 * de 7 días (en realidad 8) como "aguda", con un ratio ~7 veces mayor.
 */
public record CrossRegulationState(UUID userId, double acuteDailyLoad, double chronicDailyLoad,
                                   int maxStudyMinutes, Integer daysUntilExam, Instant updatedAt) {

    public static final int ACUTE_DAYS = 7;
    public static final int CHRONIC_DAYS = 28;

    public CrossRegulationState {
        Guard.notNull(userId, "userId");
        Guard.notNull(updatedAt, "updatedAt");
    }

    /**
     * Recalcula el estado a partir de las sumas de carga de 7 y 28 días.
     *
     * <p>Sin carga anterior a la ventana aguda (días 8-28) no hay línea base y el ACWR no significa
     * nada: en la primera semana de un usuario saldría ~4 y le avisaría de sobreentrenamiento. En ese
     * caso la carga crónica se guarda a 0, el ACWR queda nulo (columna {@code acwr_actual} incluida,
     * que también lee Entrenamiento) y la zona es NO_DATA hasta que haya historial.
     */
    public static CrossRegulationState compute(UUID userId, double acuteSum7d, double chronicSum28d,
                                               Integer daysUntilExam, Instant now) {
        boolean hasBaseline = chronicSum28d - acuteSum7d > 0;
        if (!hasBaseline) {
            chronicSum28d = 0;
        }
        Double acwr = CrossRegulation.acwr(acuteSum7d, chronicSum28d);
        int maxStudy = acwr == null
                ? CrossRegulation.DEFAULT_STUDY_MINUTES
                : CrossRegulation.maxStudyMinutes(CrossRegulation.DEFAULT_STUDY_MINUTES, acwr);
        return new CrossRegulationState(userId, acuteSum7d / ACUTE_DAYS, chronicSum28d / CHRONIC_DAYS,
                maxStudy, daysUntilExam, now);
    }

    /** Media diaria 7d / media diaria 28d; null sin historial. */
    public Double acwr() {
        return chronicDailyLoad <= 0 ? null : acuteDailyLoad / chronicDailyLoad;
    }

    public AcwrZone zone() {
        return AcwrZone.of(acwr());
    }

    /**
     * Factor de volumen de entrenamiento recomendado (fórmula 3A, {@code V_base = 1}). Sin examen
     * pendiente no hay penalización.
     *
     * @param academicLoad carga académica normalizada 0-1 (C_max = 1)
     */
    public double recommendedVolumeFactor(double academicLoad) {
        if (daysUntilExam == null) {
            return 1.0;
        }
        return CrossRegulation.modifiedVolume(1.0, academicLoad, 1.0, Math.max(0, daysUntilExam));
    }
}
