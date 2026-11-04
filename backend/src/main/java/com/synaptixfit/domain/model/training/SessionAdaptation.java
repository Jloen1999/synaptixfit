package com.synaptixfit.domain.model.training;

import java.util.ArrayList;
import java.util.List;

/**
 * Regulación cruzada aplicada a una sesión: cuánto volumen (series) se recorta hoy y por qué. Es la
 * otra mitad de la regulación (estudio → entrenamiento): antes el aviso decía «baja la intensidad» pero la
 * sesión salía igual.
 *
 * <ul>
 *   <li>Examen cerca: el factor de volumen de la fórmula 3A ({@code CrossRegulationState.recommendedVolumeFactor}).</li>
 *   <li>Sobreentrenamiento (ACWR &gt; 1,5): {@value #OVERTRAINING_FACTOR}, la descarga que recomienda Gabbett (2016)
 *       al salir de la zona óptima.</li>
 *   <li>Registro de hoy con fatiga alta ({@link DailyCheckIn#requiresAdaptation()}): {@value #HIGH_FATIGUE_FACTOR}.</li>
 * </ul>
 * <ul>
 *   <li>Seguimiento del ciclo activo y hoy con energía baja o alguna molestia ({@link CycleDay#asksForGentlerTraining()}):
 *       {@value #CYCLE_FACTOR}, un ajuste suave (ADR 0033).</li>
 * </ul>
 * Se aplica el más restrictivo (no se multiplican: tres motivos a la vez no deben dejar la sesión en nada) y
 * solo si recorta al menos un 5 %. Cada ejercicio conserva como mínimo una serie.
 */
public record SessionAdaptation(double volumeFactor, List<Reason> reasons, FatigueCause fatigueCause) {

    public static final double OVERTRAINING_FACTOR = 0.7;
    public static final double HIGH_FATIGUE_FACTOR = 0.8;
    /** Ajuste suave por el ciclo: una de cada diez series menos, nunca tanto como la fatiga alta. */
    public static final double CYCLE_FACTOR = 0.9;
    static final double MIN_CUT = 0.95;
    public static final SessionAdaptation NONE = new SessionAdaptation(1.0, List.of());

    /** Por qué se adapta la sesión (el cliente pone el texto). */
    public enum Reason {
        EXAM_SOON,
        OVERTRAINING,
        HIGH_FATIGUE,
        CYCLE_DISCOMFORT
    }

    public SessionAdaptation {
        reasons = List.copyOf(reasons);
    }

    public SessionAdaptation(double volumeFactor, List<Reason> reasons) {
        this(volumeFactor, reasons, null);
    }

    /**
     * @param examVolumeFactor factor de la fórmula 3A (1 sin examen pendiente)
     * @param overtraining     el ACWR está en la zona de sobreentrenamiento
     * @param checkIn          registro de hoy (null si no hay)
     */
    public static SessionAdaptation of(double examVolumeFactor, boolean overtraining, DailyCheckIn checkIn) {
        return of(examVolumeFactor, overtraining, checkIn, null);
    }

    /**
     * Igual, con el día del ciclo de hoy ({@code null} si el seguimiento está apagado o no se apuntó). La causa de
     * la fatiga solo se informa si la fatiga alta es uno de los motivos.
     */
    public static SessionAdaptation of(double examVolumeFactor, boolean overtraining, DailyCheckIn checkIn,
                                       CycleDay cycleDay) {
        double factor = 1.0;
        List<Reason> reasons = new ArrayList<>();
        if (examVolumeFactor < MIN_CUT) {
            factor = Math.min(factor, examVolumeFactor);
            reasons.add(Reason.EXAM_SOON);
        }
        if (overtraining) {
            factor = Math.min(factor, OVERTRAINING_FACTOR);
            reasons.add(Reason.OVERTRAINING);
        }
        if (checkIn != null && checkIn.requiresAdaptation()) {
            factor = Math.min(factor, HIGH_FATIGUE_FACTOR);
            reasons.add(Reason.HIGH_FATIGUE);
        }
        if (cycleDay != null && cycleDay.asksForGentlerTraining()) {
            factor = Math.min(factor, CYCLE_FACTOR);
            reasons.add(Reason.CYCLE_DISCOMFORT);
        }
        FatigueCause cause = reasons.contains(Reason.HIGH_FATIGUE) ? checkIn.mainCause() : null;
        return reasons.isEmpty() ? NONE : new SessionAdaptation(factor, reasons, cause);
    }

    public boolean adapted() {
        return !reasons.isEmpty();
    }

    /** Series de hoy para un ejercicio planificado con {@code plannedSets}. */
    public int sets(int plannedSets) {
        return sets(plannedSets, 0);
    }

    /**
     * Igual, pero nunca por debajo de las series ya completadas: la adaptación se recalcula al abrir la sesión
     * (p. ej. tras guardar el registro de hoy a mitad) y no debe dejar series hechas fuera del plan.
     */
    public int sets(int plannedSets, int alreadyCompleted) {
        int adaptedSets = adapted() ? Math.max(1, (int) Math.round(plannedSets * volumeFactor)) : plannedSets;
        return Math.max(adaptedSets, Math.min(plannedSets, alreadyCompleted));
    }
}
