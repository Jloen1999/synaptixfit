package com.synaptixfit.domain.model.training;

/** Fase de periodización de una semana de rutina. */
public enum WeekType {
    ADAPTATION,
    LOAD,
    PEAK,
    DELOAD;

    /**
     * Tipo por defecto según la posición: 1 semana → carga; la primera de varias → adaptación; la
     * última de 4 o más → descarga; la última de 3 → pico; el resto → carga.
     */
    public static WeekType forPosition(int weekNumber, int totalWeeks) {
        if (totalWeeks <= 1) {
            return LOAD;
        }
        if (weekNumber == 1) {
            return ADAPTATION;
        }
        if (weekNumber == totalWeeks && totalWeeks >= 4) {
            return DELOAD;
        }
        if (weekNumber == totalWeeks && totalWeeks >= 3) {
            return PEAK;
        }
        return LOAD;
    }
}
