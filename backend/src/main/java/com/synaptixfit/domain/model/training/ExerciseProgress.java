package com.synaptixfit.domain.model.training;

import com.synaptixfit.domain.model.training.generation.CompletedSessionSummary;
import com.synaptixfit.domain.model.training.generation.ProgressionCalculator;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;
import java.util.UUID;

/**
 * Evolución de un ejercicio para la gráfica (ADR 0032): por cada día que se hizo, el peso máximo estimado
 * («lo máximo que podrías levantar una vez») y la mejor serie real.
 *
 * <p>Reglas: solo cuentan las series de trabajo completadas con peso y entre 1 y {@link #MAX_REPS}
 * repeticiones; con más repeticiones la estimación deja de ser fiable. El máximo se estima con
 * {@link ProgressionCalculator#oneRepMax} (la misma fórmula que usa la progresión de cargas,
 * {@code formulas.md}). Si un día hay varias sesiones, se queda la mejor.
 */
public final class ExerciseProgress {

    /** Repeticiones hasta las que la estimación del máximo es razonable. */
    public static final int MAX_REPS = 12;

    /** Punto de la gráfica: día, máximo estimado y la serie que lo dio. */
    public record Point(LocalDate date, double estimatedMaxKg, double weightKg, int reps) {
    }

    private ExerciseProgress() {
    }

    public static List<Point> of(UUID exerciseId, List<CompletedSessionSummary> sessions, ZoneId zone) {
        Map<LocalDate, Point> byDay = new TreeMap<>();
        for (CompletedSessionSummary session : sessions) {
            LocalDate day = LocalDate.ofInstant(session.completedAt(), zone);
            for (CompletedSessionSummary.PerformedSet performed : session.sets()) {
                SessionSet set = performed.set();
                if (!exerciseId.equals(performed.exerciseId()) || !set.completed() || set.warmup()
                        || set.weightKg() == null || set.weightKg() <= 0 || set.repsDone() == null
                        || set.repsDone() < 1 || set.repsDone() > MAX_REPS) {
                    continue;
                }
                double estimate = Math.round(ProgressionCalculator.oneRepMax(set.weightKg(), set.repsDone()) * 10)
                        / 10.0;
                Point candidate = new Point(day, estimate, set.weightKg(), set.repsDone());
                byDay.merge(day, candidate, (a, b) -> a.estimatedMaxKg() >= b.estimatedMaxKg() ? a : b);
            }
        }
        List<Point> points = new ArrayList<>(byDay.values());
        points.sort(Comparator.comparing(Point::date));
        return points;
    }
}
