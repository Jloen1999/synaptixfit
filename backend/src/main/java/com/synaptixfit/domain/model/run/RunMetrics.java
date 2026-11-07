package com.synaptixfit.domain.model.run;

import java.util.List;

/**
 * Cifras de una carrera calculadas en el servidor a partir de la ruta ({@link RunTrack#analyze}).
 *
 * @param points           puntos que pasaron el filtro (los que se guardan y se dibujan)
 * @param elapsedSeconds   del primer al último punto, pausas incluidas
 * @param movingSeconds    solo el tiempo en movimiento (sin pausas ni ratos parado)
 */
public record RunMetrics(List<TrackPoint> points, int distanceMeters, int movingSeconds, int elapsedSeconds,
                         int elevationGainMeters, List<KmSplit> splits) {

    public RunMetrics {
        points = List.copyOf(points);
        splits = List.copyOf(splits);
    }

    /** Ritmo medio en segundos por km; nulo con menos de {@link RunTrack#MIN_SPLIT_METERS} m. */
    public Integer paceSecondsPerKm() {
        if (distanceMeters < RunTrack.MIN_SPLIT_METERS || movingSeconds <= 0) {
            return null;
        }
        return (int) Math.round(movingSeconds * 1000.0 / distanceMeters);
    }

    /** Velocidad media en movimiento, en km/h (0 si no hubo movimiento). */
    public double speedKmh() {
        return movingSeconds <= 0 ? 0 : distanceMeters / 1000.0 / (movingSeconds / 3600.0);
    }

    /** Minutos en movimiento redondeados: los que cuentan para la carga física y la XP. */
    public int movingMinutes() {
        return (int) Math.round(movingSeconds / 60.0);
    }
}
