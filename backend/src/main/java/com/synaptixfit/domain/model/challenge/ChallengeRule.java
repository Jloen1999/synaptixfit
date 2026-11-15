package com.synaptixfit.domain.model.challenge;

import com.synaptixfit.domain.model.shared.Guard;
import com.synaptixfit.domain.model.user.UsageFocus;
import java.time.DayOfWeek;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.ZoneId;
import java.time.temporal.TemporalAdjusters;
import java.util.Collection;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * Regla de un reto que se cuenta solo (ADR 0043): «{@code perUnit} {@code metric} cada {@code unit}, {@code target}
 * veces». Ejemplos: un repaso al día, 12 días (de 14); 3 entrenos por semana, 3 semanas; 18 carreras en total.
 *
 * <p>Qué cuenta:
 * <ul>
 *   <li>Solo lo hecho dentro del reto: lo que tiene instante, entre su inicio y su fin; lo que solo tiene fecha, entre
 *       el día de inicio y el de fin (en la zona de la persona).</li>
 *   <li>DAY: días (de lunes a viernes si {@code weekdaysOnly}) cuya suma llega a {@code perUnit}. WEEK: semanas de
 *       lunes a domingo que llegan; cuentan también las que el reto pisa a medias. TOTAL: la suma de todo el
 *       periodo (minutos, carreras…), y {@code perUnit} no se usa.</li>
 *   <li>EARLY_FOCUS: el Pomodoro cuenta si empezó (fin − minutos) antes de las {@value #EARLY_HOUR}:00.
 *       STUDY_AND_MOVE: el día cuenta si tiene a la vez un Pomodoro y un entreno.</li>
 * </ul>
 * El recuento se rehace desde cero cada vez (idempotente) y nunca pasa de {@code target}.
 */
public record ChallengeRule(RuleMetric metric, RuleUnit unit, int perUnit, int target, boolean weekdaysOnly) {

    /** Hora (local) antes de la que un Pomodoro cuenta como «primer estudio temprano». */
    public static final int EARLY_HOUR = 10;
    public static final int MAX_TARGET = 10_000;

    public ChallengeRule {
        Guard.notNull(metric, "metric");
        Guard.notNull(unit, "unit");
        Guard.range(perUnit, "perUnit", 1, MAX_TARGET);
        Guard.range(target, "target", 1, MAX_TARGET);
    }

    /** Sale de datos de bienestar: el reto se queda privado (no se comparte nunca). */
    public boolean privateOnly() {
        return metric.wellbeing();
    }

    /** Si quien tiene ese modo de uso puede hacer todo lo que cuenta. */
    public boolean availableFor(UsageFocus focus) {
        return metric.sources().stream().allMatch(k -> k.availableFor(focus));
    }

    /** Cuántas unidades (días, semanas o suma) se han cumplido entre {@code start} y {@code end}, hasta {@code target}. */
    public int count(Collection<ActivityFact> facts, Instant start, Instant end, ZoneId zone) {
        LocalDate firstDay = LocalDate.ofInstant(start, zone);
        LocalDate lastDay = LocalDate.ofInstant(end, zone);
        List<ActivityFact> inside = facts.stream()
                .filter(f -> metric.sources().contains(f.kind()))
                .filter(f -> f.at() != null
                        ? !f.at().isBefore(start) && !f.at().isAfter(end)
                        : !f.day().isBefore(firstDay) && !f.day().isAfter(lastDay))
                .filter(f -> metric != RuleMetric.EARLY_FOCUS || startedEarly(f, zone))
                .toList();
        int met = switch (unit) {
            case TOTAL -> inside.stream().mapToInt(this::valueOf).sum();
            case DAY -> countBuckets(inside, zone, false);
            case WEEK -> countBuckets(inside, zone, true);
        };
        return Math.min(met, target);
    }

    private int countBuckets(List<ActivityFact> facts, ZoneId zone, boolean weekly) {
        Map<LocalDate, Integer> sums = new HashMap<>();
        Map<LocalDate, Set<ActivityKind>> kinds = new HashMap<>();
        for (ActivityFact f : facts) {
            LocalDate day = f.dayIn(zone);
            if (weekdaysOnly && day.getDayOfWeek().getValue() >= DayOfWeek.SATURDAY.getValue()) {
                continue;
            }
            LocalDate bucket = weekly ? day.with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY)) : day;
            sums.merge(bucket, valueOf(f), Integer::sum);
            kinds.computeIfAbsent(bucket, k -> new HashSet<>()).add(f.kind());
        }
        if (metric == RuleMetric.STUDY_AND_MOVE) {
            return (int) kinds.values().stream().filter(k -> k.containsAll(metric.sources())).count();
        }
        return (int) sums.values().stream().filter(v -> v >= perUnit).count();
    }

    /** Minutos en un reto de minutos de Pomodoro; 1 por cosa hecha en el resto. */
    private int valueOf(ActivityFact f) {
        return metric == RuleMetric.FOCUS_MINUTES ? f.amount() : 1;
    }

    private static boolean startedEarly(ActivityFact f, ZoneId zone) {
        if (f.at() == null) {
            return false;
        }
        LocalTime started = f.at().minusSeconds(60L * f.amount()).atZone(zone).toLocalTime();
        return started.isBefore(LocalTime.of(EARLY_HOUR, 0));
    }
}
