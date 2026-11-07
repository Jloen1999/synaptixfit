package com.synaptixfit.domain.model.run;

import com.synaptixfit.domain.model.planner.ActivityKind;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * Detalle de una carrera para su pantalla: cifras, tramos por km y la ruta reducida a
 * {@link #ROUTE_POINTS} puntos para dibujarla (la ruta es siempre privada: solo la ve su dueño).
 *
 * @param title nombre del evento (el del entreno de carrera, si se grabó con uno)
 */
public record RunDetail(UUID blockId, ActivityKind kind, String title, Instant startedAt, Instant endedAt,
                        int distanceMeters, int movingSeconds, int elevationGainMeters, Integer kcal, int effort,
                        List<KmSplit> splits, List<TrackPoint> route, UUID workoutId) {

    public static final int ROUTE_POINTS = 600;

    public RunDetail {
        splits = List.copyOf(splits);
        route = List.copyOf(route);
    }

    public Integer paceSecondsPerKm() {
        if (distanceMeters < RunTrack.MIN_SPLIT_METERS || movingSeconds <= 0) {
            return null;
        }
        return (int) Math.round(movingSeconds * 1000.0 / distanceMeters);
    }
}
