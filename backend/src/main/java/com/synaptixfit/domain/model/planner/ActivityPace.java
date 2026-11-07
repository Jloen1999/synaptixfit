package com.synaptixfit.domain.model.planner;

/**
 * Ritmo y velocidad de una actividad con distancia (formulas.md, «Ritmo»): segundos por kilómetro =
 * minutos × 60 ÷ km, y km/h = km ÷ (minutos ÷ 60). Se redondea a segundos enteros y a una décima. El cliente enseña
 * el ritmo al correr o andar y la velocidad en bici; nadando, el ritmo por 100 m (segundos ÷ (metros ÷ 100)), que
 * también da el servidor para que el cliente solo lo pinte.
 */
public record ActivityPace(int secondsPerKm, double kmPerHour, int secondsPer100m) {

    public ActivityPace(int secondsPerKm, double kmPerHour) {
        this(secondsPerKm, kmPerHour, (int) Math.round(secondsPerKm / 10.0));
    }

    /** @return nulo si no hay distancia o minutos */
    public static ActivityPace of(int minutes, Integer distanceMeters) {
        if (distanceMeters == null || distanceMeters <= 0 || minutes <= 0) {
            return null;
        }
        double km = distanceMeters / 1000.0;
        int perKm = (int) Math.round(minutes * 60 / km);
        double speed = Math.round(km / (minutes / 60.0) * 10) / 10.0;
        int per100m = (int) Math.round(minutes * 60 / (distanceMeters / 100.0));
        return new ActivityPace(perKm, speed, per100m);
    }
}
