package com.synaptixfit.domain.model.planner;

/**
 * Ritmo y velocidad de una actividad con distancia (formulas.md, «Ritmo»): segundos por kilómetro =
 * minutos × 60 ÷ km, y km/h = km ÷ (minutos ÷ 60). Se redondea a segundos enteros y a una décima. El cliente enseña
 * el ritmo al correr o andar y la velocidad en bici; nadando, el ritmo por 100 m (la décima parte).
 */
public record ActivityPace(int secondsPerKm, double kmPerHour) {

    /** @return nulo si no hay distancia o minutos */
    public static ActivityPace of(int minutes, Integer distanceMeters) {
        if (distanceMeters == null || distanceMeters <= 0 || minutes <= 0) {
            return null;
        }
        double km = distanceMeters / 1000.0;
        int perKm = (int) Math.round(minutes * 60 / km);
        double speed = Math.round(km / (minutes / 60.0) * 10) / 10.0;
        return new ActivityPace(perKm, speed);
    }
}
