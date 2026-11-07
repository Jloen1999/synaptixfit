package com.synaptixfit.domain.model.run;

import com.synaptixfit.domain.model.planner.PlannerZone;
import java.time.Instant;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.Arrays;
import java.util.List;

/**
 * Tarjeta «Esta semana» de Correr: distancia, tiempo en movimiento, desnivel y salidas de lunes a domingo, con la
 * distancia de cada día para la mini gráfica. Suma las actividades que se miden en distancia (correr, andar y bici),
 * grabadas con GPS o apuntadas a mano; las apuntadas a mano no tienen desnivel.
 */
public record RunWeek(LocalDate weekStart, int distanceMeters, int movingSeconds, int elevationGainMeters,
                      int outings, List<Integer> dailyDistanceMeters) {

    /** Una actividad de la semana: cuándo empezó y sus cifras. */
    public record Outing(Instant start, int distanceMeters, int movingSeconds, Integer elevationGainMeters) {
    }

    public RunWeek {
        dailyDistanceMeters = List.copyOf(dailyDistanceMeters);
    }

    public static RunWeek of(LocalDate monday, List<Outing> outings, PlannerZone zone) {
        int[] daily = new int[7];
        int distance = 0;
        int moving = 0;
        int elevation = 0;
        int count = 0;
        for (Outing o : outings) {
            long day = ChronoUnit.DAYS.between(monday, zone.localDate(o.start()));
            if (day < 0 || day > 6) {
                continue;
            }
            daily[(int) day] += o.distanceMeters();
            distance += o.distanceMeters();
            moving += o.movingSeconds();
            elevation += o.elevationGainMeters() == null ? 0 : o.elevationGainMeters();
            count++;
        }
        return new RunWeek(monday, distance, moving, elevation, count,
                Arrays.stream(daily).boxed().toList());
    }
}
