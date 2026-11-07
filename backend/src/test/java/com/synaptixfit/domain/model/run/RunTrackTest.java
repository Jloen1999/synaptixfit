package com.synaptixfit.domain.model.run;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.assertj.core.api.Assertions.within;

import com.synaptixfit.domain.exception.FieldValidationException;
import com.synaptixfit.domain.exception.run.RunRouteTooLargeException;
import com.synaptixfit.domain.model.planner.ActivityKind;
import java.util.ArrayList;
import java.util.List;
import org.junit.jupiter.api.Test;

/** Cálculos de una carrera con trazas de ejemplo: filtrado, distancia, movimiento, tramos por km y desnivel. */
class RunTrackTest {

    /** Metros por grado de latitud con el radio de {@link TrackPoint}. */
    private static final double METERS_PER_DEGREE = Math.toRadians(1) * TrackPoint.EARTH_RADIUS_METERS;
    private static final double LAT = 40.4168;
    private static final double LON = -3.7038;

    /** Hacia el norte a {@code speed} m/s, un punto por segundo durante {@code seconds} s. */
    private static List<TrackPoint> straight(double speed, int seconds, int segment, double fromSecond,
                                             double fromMeters) {
        List<TrackPoint> points = new ArrayList<>();
        for (int i = 0; i <= seconds; i++) {
            double meters = fromMeters + speed * i;
            points.add(new TrackPoint(LAT + meters / METERS_PER_DEGREE, LON, 650.0, 5, fromSecond + i, segment));
        }
        return points;
    }

    @Test
    void haversineMatchesAKnownDistance() {
        TrackPoint madrid = new TrackPoint(40.4168, -3.7038, null, 5, 0, 0);
        TrackPoint barcelona = new TrackPoint(41.3874, 2.1686, null, 5, 1, 0);
        // Distancia de círculo máximo Madrid-Barcelona: ≈ 505 km.
        assertThat(madrid.distanceTo(barcelona)).isCloseTo(505_000, within(2_000.0));
    }

    @Test
    void steadyRunGivesDistanceMovingTimeAndPace() {
        // 20 min a 3 m/s = 3600 m a 5:33 min/km.
        RunMetrics m = RunTrack.analyze(straight(3, 1200, 0, 0, 0), ActivityKind.RUN);

        assertThat(m.distanceMeters()).isCloseTo(3600, within(5));
        assertThat(m.movingSeconds()).isCloseTo(1200, within(2));
        assertThat(m.paceSecondsPerKm()).isCloseTo(333, within(1));
        assertThat(m.movingMinutes()).isEqualTo(20);
        assertThat(m.splits()).hasSize(4);
        assertThat(m.splits().getFirst().distanceMeters()).isEqualTo(1000);
        assertThat(m.splits().getFirst().seconds()).isCloseTo(333, within(2));
        // El último tramo, incompleto: 600 m al mismo ritmo.
        KmSplit last = m.splits().getLast();
        assertThat(last.number()).isEqualTo(4);
        assertThat(last.distanceMeters()).isCloseTo(600, within(5));
        assertThat(last.paceSecondsPerKm()).isCloseTo(333, within(3));
    }

    @Test
    void inaccurateAndImpossibleJumpsAreDiscarded() {
        List<TrackPoint> points = new ArrayList<>(straight(3, 600, 0, 0, 0));
        // Un punto con 80 m de precisión y un salto de 2 km en un segundo (rebote del GPS): no suman nada.
        points.add(301, new TrackPoint(LAT + 0.01, LON, 650.0, 80, 300.5, 0));
        points.add(402, new TrackPoint(LAT + 2000 / METERS_PER_DEGREE, LON, 650.0, 5, 400.5, 0));

        RunMetrics m = RunTrack.analyze(points, ActivityKind.RUN);

        assertThat(m.distanceMeters()).isCloseTo(1800, within(5));
        assertThat(m.points()).hasSize(601);
    }

    @Test
    void standingStillWithGpsDriftAddsNoDistanceNorMovingTime() {
        List<TrackPoint> points = new ArrayList<>(straight(3, 300, 0, 0, 0));
        // 3 minutos parado en un semáforo: el GPS baila ±2 m alrededor del mismo sitio.
        double at = 900;
        for (int i = 1; i <= 180; i++) {
            double jitter = (i % 2 == 0 ? 2 : -2) / METERS_PER_DEGREE;
            points.add(new TrackPoint(LAT + at / METERS_PER_DEGREE + jitter, LON, 650.0, 5, 300 + i, 0));
        }
        points.addAll(straight(3, 300, 0, 481, 900).subList(1, 301));

        RunMetrics m = RunTrack.analyze(points, ActivityKind.RUN);

        assertThat(m.distanceMeters()).isCloseTo(1800, within(10));
        assertThat(m.movingSeconds()).isCloseTo(600, within(15));
        assertThat(m.elapsedSeconds()).isEqualTo(781);
    }

    @Test
    void pausesSplitSegmentsSoTheGapIsNotCounted() {
        List<TrackPoint> points = new ArrayList<>(straight(3, 300, 0, 0, 0));
        // Pausa: se camina 500 m sin grabar y se reanuda en otro segmento.
        points.addAll(straight(3, 300, 1, 600, 1400));

        RunMetrics m = RunTrack.analyze(points, ActivityKind.RUN);

        assertThat(m.distanceMeters()).isCloseTo(1800, within(5));
        assertThat(m.movingSeconds()).isCloseTo(600, within(2));
    }

    @Test
    void elevationGainIgnoresGpsNoiseAndCountsRealClimbs() {
        List<TrackPoint> points = new ArrayList<>();
        for (int i = 0; i <= 600; i++) {
            // Sube 30 m en los 10 minutos con ruido de ±2 m en cada punto.
            double altitude = 600 + 30.0 * i / 600 + (i % 2 == 0 ? 2 : -2);
            points.add(new TrackPoint(LAT + 3.0 * i / METERS_PER_DEGREE, LON, altitude, 5, i, 0));
        }
        RunMetrics climb = RunTrack.analyze(points, ActivityKind.RUN);
        assertThat(climb.elevationGainMeters()).isBetween(26, 32);

        List<TrackPoint> flat = new ArrayList<>();
        for (int i = 0; i <= 600; i++) {
            flat.add(new TrackPoint(LAT + 3.0 * i / METERS_PER_DEGREE, LON, 600 + (i % 2 == 0 ? 2.5 : -2.5), 5, i,
                    0));
        }
        assertThat(RunTrack.analyze(flat, ActivityKind.RUN).elevationGainMeters()).isZero();
    }

    @Test
    void limitsOnTheNumberOfPoints() {
        assertThatThrownBy(() -> RunTrack.analyze(List.of(new TrackPoint(LAT, LON, null, 5, 0, 0)),
                ActivityKind.RUN)).isInstanceOf(FieldValidationException.class);
        List<TrackPoint> huge = straight(1, RunTrack.MAX_POINTS, 0, 0, 0);
        assertThatThrownBy(() -> RunTrack.analyze(huge, ActivityKind.RUN))
                .isInstanceOf(RunRouteTooLargeException.class);
    }

    @Test
    void bikeAllowsFasterSpeedsThanRunning() {
        // 15 m/s (54 km/h) es imposible corriendo, pero no en bici bajando.
        List<TrackPoint> fast = straight(15, 120, 0, 0, 0);
        assertThat(RunTrack.analyze(fast, ActivityKind.RUN).distanceMeters()).isZero();
        assertThat(RunTrack.analyze(fast, ActivityKind.BIKE).distanceMeters()).isCloseTo(1800, within(5));
    }

    @Test
    void simplifyKeepsFirstAndLast() {
        List<TrackPoint> points = straight(3, 1000, 0, 0, 0);
        List<TrackPoint> small = RunTrack.simplify(points, 100);
        assertThat(small).hasSize(100);
        assertThat(small.getFirst()).isEqualTo(points.getFirst());
        assertThat(small.getLast()).isEqualTo(points.getLast());
    }

    @Test
    void kcalFollowsMetTimesWeightTimesHours() {
        // 10 km/h corriendo: VO₂ = 3,5 + 0,2·166,7 = 36,8 → 10,5 MET; 70 kg · 1 h ≈ 736 kcal.
        assertThat(RunEnergy.met(ActivityKind.RUN, 10)).isCloseTo(10.52, within(0.01));
        RunMetrics hour = new RunMetrics(List.of(), 10_000, 3600, 3600, 0, List.of());
        assertThat(RunEnergy.kcal(ActivityKind.RUN, hour, 70.0)).isCloseTo(736, within(2));
        assertThat(RunEnergy.met(ActivityKind.WALK, 5)).isCloseTo(3.38, within(0.01));
        assertThat(RunEnergy.met(ActivityKind.BIKE, 20)).isEqualTo(8.0);
    }
}
