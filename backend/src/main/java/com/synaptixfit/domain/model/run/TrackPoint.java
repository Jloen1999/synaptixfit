package com.synaptixfit.domain.model.run;

import com.synaptixfit.domain.exception.FieldValidationException;

/**
 * Un punto de la ruta que manda el móvil al grabar con el GPS (ADR 0037). La hora va en segundos desde el inicio
 * para no repetir la fecha en cada punto; {@code segment} cambia con cada pausa, así el tramo entre pausar y
 * reanudar no suma distancia ni tiempo.
 *
 * @param altitude altitud en metros (nula si el GPS no la da)
 * @param accuracy precisión horizontal en metros que da el GPS (cuanto menor, mejor)
 */
public record TrackPoint(double latitude, double longitude, Double altitude, double accuracy, double offsetSeconds,
                         int segment) {

    /** Radio medio de la Tierra (UGGI), el habitual en la fórmula de haversine. */
    static final double EARTH_RADIUS_METERS = 6_371_008.8;

    public TrackPoint {
        if (!Double.isFinite(latitude) || latitude < -90 || latitude > 90
                || !Double.isFinite(longitude) || longitude < -180 || longitude > 180
                || !Double.isFinite(accuracy) || accuracy < 0
                || !Double.isFinite(offsetSeconds) || offsetSeconds < 0
                || segment < 0
                || (altitude != null && !Double.isFinite(altitude))) {
            throw new FieldValidationException("points", "OUT_OF_RANGE", "invalid track point");
        }
    }

    /** Distancia en metros por la superficie de la Tierra (haversine; error < 0,5 % frente al elipsoide). */
    public double distanceTo(TrackPoint other) {
        double lat1 = Math.toRadians(latitude);
        double lat2 = Math.toRadians(other.latitude);
        double dLat = lat2 - lat1;
        double dLon = Math.toRadians(other.longitude - longitude);
        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2)
                + Math.cos(lat1) * Math.cos(lat2) * Math.sin(dLon / 2) * Math.sin(dLon / 2);
        return 2 * EARTH_RADIUS_METERS * Math.asin(Math.min(1, Math.sqrt(a)));
    }
}
