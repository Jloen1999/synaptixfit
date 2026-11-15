package com.synaptixfit.domain.model.training;

/**
 * «Hoy toca: suave / normal / fuerte» (ADR 0042), la línea de «Tu día» en Inicio. Resume en una palabra la
 * adaptación de hoy ({@link SessionAdaptation}) y el registro diario ({@link DailyCheckIn}); el cliente solo pone
 * el texto.
 *
 * <ul>
 *   <li>{@link #EASY}: la sesión se adapta por algún motivo (examen cerca, sobrecarga, fatiga alta o el ciclo).
 *       Manda sobre lo demás: si hay que recortar, no es día de apretar.</li>
 *   <li>{@link #HARD}: sin ningún motivo para recortar y el registro de hoy dice que estás bien
 *       ({@link DailyCheckIn#feelsStrong()}). Sin registro no se propone fuerte: no hay datos para ello.</li>
 *   <li>{@link #NORMAL}: lo demás.</li>
 * </ul>
 */
public enum TodayIntensity {
    EASY,
    NORMAL,
    HARD;

    /** @param checkIn registro de hoy, o nulo si aún no hay */
    public static TodayIntensity of(SessionAdaptation adaptation, DailyCheckIn checkIn) {
        if (adaptation != null && adaptation.adapted()) {
            return EASY;
        }
        return checkIn != null && checkIn.feelsStrong() ? HARD : NORMAL;
    }
}
