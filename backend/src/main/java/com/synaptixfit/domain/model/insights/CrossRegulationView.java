package com.synaptixfit.domain.model.insights;

/**
 * Lectura del estado de regulación cruzada con los valores derivados.
 *
 * @param academicLoad carga académica 0-1 usada para el factor de volumen (FCT de la semana si hay
 *                     carga académica registrada; si no, la carga cognitiva acumulada de hoy)
 */
public record CrossRegulationView(CrossRegulationState state, Double acwr, AcwrZone zone, double academicLoad,
                                  double recommendedVolumeFactor) {
}
