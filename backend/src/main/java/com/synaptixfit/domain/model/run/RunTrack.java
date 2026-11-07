package com.synaptixfit.domain.model.run;

import com.synaptixfit.domain.exception.FieldValidationException;
import com.synaptixfit.domain.exception.run.RunRouteTooLargeException;
import com.synaptixfit.domain.model.planner.ActivityKind;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

/**
 * Análisis de la ruta de una carrera (formulas.md, «Carreras con GPS», ADR 0037). Todo se calcula aquí, nunca en
 * el cliente: filtrado de puntos, distancia (haversine), tiempo en movimiento, tramos por kilómetro y desnivel
 * positivo.
 *
 * <ol>
 *   <li><b>Filtrado:</b> fuera los puntos con precisión peor que {@value #MAX_ACCURACY_METERS} m, los que no
 *   avanzan en el tiempo y los «saltos imposibles» (más rápido que {@link #maxSpeed} para la clase de deporte).</li>
 *   <li><b>Distancia y movimiento:</b> se avanza desde un punto ancla y solo se suma un paso cuando se aleja al
 *   menos {@value #MIN_STEP_METERS} m, así el baile del GPS estando parado no suma metros. El paso cuenta como
 *   movimiento si va a {@value #MIN_MOVING_SPEED} m/s o más; si se tarda más de {@value #STILL_SECONDS} s sin
 *   alejarse, se estaba parado y el ancla se mueve sin sumar tiempo. Entre segmentos (pausas) no se suma nada.</li>
 *   <li><b>Tramos por km:</b> se interpola el momento exacto en que se cruza cada kilómetro.</li>
 *   <li><b>Desnivel positivo:</b> la altitud del GPS es ruidosa (±10 m): se suaviza con una media móvil de
 *   {@value #ELEVATION_WINDOW} puntos y la altitud de referencia solo cambia con subidas o bajadas de
 *   {@value #ELEVATION_THRESHOLD_METERS} m o más (histéresis); se suman las subidas.</li>
 * </ol>
 */
public final class RunTrack {

    /** Unas 5,5 h a un punto por segundo; el móvil graba como mucho uno por segundo. */
    public static final int MAX_POINTS = 20_000;
    public static final double MAX_ACCURACY_METERS = 25;
    public static final double MIN_STEP_METERS = 5;
    public static final double MIN_MOVING_SPEED = 0.5;
    public static final double STILL_SECONDS = 10;
    public static final int ELEVATION_WINDOW = 5;
    public static final double ELEVATION_THRESHOLD_METERS = 3;
    /** El último tramo, incompleto, solo se enseña desde 100 m. */
    public static final int MIN_SPLIT_METERS = 100;

    private RunTrack() {
    }

    /** Velocidad máxima creíble (m/s): por encima de un sprint de élite andando o corriendo; 25 m/s en bici. */
    public static double maxSpeed(ActivityKind kind) {
        return kind == ActivityKind.BIKE ? 25 : 12;
    }

    public static RunMetrics analyze(List<TrackPoint> raw, ActivityKind kind) {
        if (raw == null || raw.size() < 2) {
            throw new FieldValidationException("points", "TOO_FEW", "a route needs at least 2 points");
        }
        if (raw.size() > MAX_POINTS) {
            throw new RunRouteTooLargeException();
        }
        List<TrackPoint> points = filter(raw, maxSpeed(kind));
        List<double[]> steps = steps(points);
        double distance = 0;
        double moving = 0;
        for (double[] step : steps) {
            distance += step[0];
            moving += step[1];
        }
        int elapsed = points.isEmpty() ? 0
                : (int) Math.round(points.getLast().offsetSeconds() - points.getFirst().offsetSeconds());
        return new RunMetrics(points, (int) Math.round(distance), (int) Math.round(moving), elapsed,
                elevationGain(points), splits(steps));
    }

    static List<TrackPoint> filter(List<TrackPoint> raw, double maxSpeed) {
        List<TrackPoint> sorted = raw.stream()
                .filter(p -> p.accuracy() <= MAX_ACCURACY_METERS)
                .sorted(Comparator.comparingDouble(TrackPoint::offsetSeconds))
                .toList();
        List<TrackPoint> kept = new ArrayList<>();
        for (TrackPoint p : sorted) {
            if (kept.isEmpty()) {
                kept.add(p);
                continue;
            }
            TrackPoint last = kept.getLast();
            double dt = p.offsetSeconds() - last.offsetSeconds();
            if (dt <= 0) {
                continue;
            }
            if (p.segment() == last.segment() && last.distanceTo(p) / dt > maxSpeed) {
                continue;
            }
            kept.add(p);
        }
        return kept;
    }

    /** Pasos en movimiento: {metros, segundos}. */
    static List<double[]> steps(List<TrackPoint> points) {
        List<double[]> steps = new ArrayList<>();
        TrackPoint anchor = null;
        for (TrackPoint p : points) {
            if (anchor == null || p.segment() != anchor.segment()) {
                anchor = p;
                continue;
            }
            double d = anchor.distanceTo(p);
            double dt = p.offsetSeconds() - anchor.offsetSeconds();
            if (d >= MIN_STEP_METERS) {
                if (d / dt >= MIN_MOVING_SPEED) {
                    steps.add(new double[] {d, dt});
                }
                anchor = p;
            } else if (dt > STILL_SECONDS) {
                anchor = p;
            }
        }
        return steps;
    }

    static List<KmSplit> splits(List<double[]> steps) {
        List<KmSplit> splits = new ArrayList<>();
        double distance = 0;
        double time = 0;
        double lastSplitTime = 0;
        int next = 1;
        for (double[] step : steps) {
            double d = step[0];
            double dt = step[1];
            while (distance + d >= next * 1000.0) {
                double fraction = (next * 1000.0 - distance) / d;
                double crossing = time + fraction * dt;
                splits.add(new KmSplit(next, 1000, (int) Math.round(crossing - lastSplitTime)));
                lastSplitTime = crossing;
                next++;
            }
            distance += d;
            time += dt;
        }
        double rest = distance - (next - 1) * 1000.0;
        if (rest >= MIN_SPLIT_METERS) {
            splits.add(new KmSplit(next, (int) Math.round(rest), (int) Math.round(time - lastSplitTime)));
        }
        return splits;
    }

    static int elevationGain(List<TrackPoint> points) {
        List<Double> altitudes = points.stream()
                .map(TrackPoint::altitude)
                .filter(a -> a != null)
                .toList();
        if (altitudes.size() < 2) {
            return 0;
        }
        int half = ELEVATION_WINDOW / 2;
        double gain = 0;
        Double reference = null;
        for (int i = 0; i < altitudes.size(); i++) {
            int from = Math.max(0, i - half);
            int to = Math.min(altitudes.size() - 1, i + half);
            double sum = 0;
            for (int j = from; j <= to; j++) {
                sum += altitudes.get(j);
            }
            double smoothed = sum / (to - from + 1);
            if (reference == null) {
                reference = smoothed;
                continue;
            }
            // La referencia solo se mueve con cambios de al menos el umbral (en los dos sentidos): si siguiera cada
            // bajada pequeña, el ruido se sumaría como subida.
            double diff = smoothed - reference;
            if (diff >= ELEVATION_THRESHOLD_METERS) {
                gain += diff;
                reference = smoothed;
            } else if (diff <= -ELEVATION_THRESHOLD_METERS) {
                reference = smoothed;
            }
        }
        return (int) Math.round(gain);
    }

    /** Hasta {@code max} puntos repartidos por la ruta (con el primero y el último) para dibujarla. */
    public static List<TrackPoint> simplify(List<TrackPoint> points, int max) {
        if (points.size() <= max || max < 2) {
            return List.copyOf(points);
        }
        List<TrackPoint> out = new ArrayList<>(max);
        double step = (points.size() - 1) / (double) (max - 1);
        for (int i = 0; i < max; i++) {
            out.add(points.get((int) Math.round(i * step)));
        }
        return out;
    }
}
