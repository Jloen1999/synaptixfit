package com.synaptixfit.domain.model.training;

/**
 * Por qué cambia un ejercicio en una sugerencia: lo decide {@code ProgressionCalculator} y el
 * cliente lo explica con sus textos (el {@code reason} libre era una nota técnica en español).
 */
public enum AdjustmentReason {
    /** Hubo repeticiones fallidas: baja la carga y se quita una serie. */
    FAILED_REPS,
    /** RPE ≥ 9,5: baja la carga. */
    VERY_HIGH_RPE,
    /** RPE ≤ 5: sube la carga. */
    VERY_LOW_RPE,
    /** RPE ≤ 7 lejos del tope de repeticiones: una repetición más. */
    LOW_RPE_MORE_REPS,
    /** RPE ≤ 7 en el tope de repeticiones: más peso y vuelta al mínimo de repeticiones. */
    LOW_RPE_MORE_WEIGHT,
    /** RPE ≤ 7 en un ejercicio por tiempo: más tiempo. */
    LOW_RPE_MORE_TIME,
    /** RPE ≤ 7 en un ejercicio por distancia: más distancia. */
    LOW_RPE_MORE_DISTANCE,
    /** Más de 14 días sin entrenar: se vuelve con menos carga. */
    INACTIVITY
}
