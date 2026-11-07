package com.synaptixfit.domain.model.training;

import java.time.Instant;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * Resumen del seguimiento del ciclo: momento estimado, día del ciclo y cuándo se espera la próxima regla.
 *
 * <p>Estimación sencilla (formulas.md, «Ciclo»): un ciclo empieza el primer día con regla tras un día sin ella.
 * La duración del ciclo es la media de los últimos {@value #CYCLES_FOR_AVERAGE} ciclos completos entre
 * {@value #MIN_CYCLE} y {@value #MAX_CYCLE} días (si no hay, {@value #DEFAULT_CYCLE}); la de la regla, la media de
 * los periodos apuntados (si no, {@value #DEFAULT_PERIOD}). Con eso: regla los primeros días, «mitad del ciclo»
 * entre 16 y 12 días antes de la próxima regla (alrededor de la ovulación, unos 14 días antes), antes «después de la
 * regla» y luego «días antes de la regla». Sin ningún inicio apuntado en los últimos {@value #MAX_DAYS_KNOWN} días no
 * se estima nada.
 */
public record CycleOverview(CycleTracking tracking, CyclePhase phase, Integer dayOfCycle, int cycleLength,
                            LocalDate nextPeriodFrom, CycleDay today) {

    public static final int DEFAULT_CYCLE = 28;
    public static final int DEFAULT_PERIOD = 5;
    public static final int MIN_CYCLE = 21;
    public static final int MAX_CYCLE = 40;
    /** Ciclos más largos que esto no entran en la media (probablemente falta apuntar una regla). */
    public static final int MAX_CYCLE_ACCEPTED = 45;
    /** Días seguidos de regla que se cuentan como mucho al medir su duración. */
    public static final int MAX_PERIOD_DAYS = 10;
    public static final int MIN_PERIOD = 2;
    public static final int MAX_PERIOD = 8;
    /** Días alrededor de la ovulación estimada que se cuentan como «mitad del ciclo». */
    public static final int OVULATION_WINDOW = 2;
    public static final int CYCLES_FOR_AVERAGE = 6;
    public static final int MAX_DAYS_KNOWN = 60;
    /** Días que se leen hacia atrás para estimar: de sobra para seis ciclos. */
    public static final int LOOKBACK_DAYS = 240;

    public static CycleOverview off() {
        return new CycleOverview(CycleTracking.OFF, null, null, DEFAULT_CYCLE, null, null);
    }

    /** @param days días apuntados de los últimos {@link #LOOKBACK_DAYS} días (en cualquier orden) */
    public static CycleOverview compute(CycleTracking tracking, List<CycleDay> days, LocalDate today) {
        if (!tracking.enabled()) {
            return off();
        }
        Map<LocalDate, CycleDay> byDate = days.stream()
                .collect(Collectors.toMap(CycleDay::date, Function.identity(), (a, b) -> b));
        CycleDay todayLog = byDate.get(today);
        List<LocalDate> starts = periodStarts(byDate);
        int cycle = averageCycle(starts);
        LocalDate lastStart = starts.stream().filter(d -> !d.isAfter(today)).max(Comparator.naturalOrder())
                .orElse(null);
        if (lastStart == null || ChronoUnit.DAYS.between(lastStart, today) >= MAX_DAYS_KNOWN) {
            return new CycleOverview(tracking, todayLog != null && todayLog.period() ? CyclePhase.PERIOD : null, null,
                    cycle, null, todayLog);
        }
        int day = (int) ChronoUnit.DAYS.between(lastStart, today) + 1;
        int period = averagePeriod(byDate, starts);
        return new CycleOverview(tracking, phaseOf(day, cycle, period, todayLog), day, cycle,
                lastStart.plusDays(cycle), todayLog);
    }

    static CyclePhase phaseOf(int day, int cycle, int period, CycleDay todayLog) {
        if (todayLog != null && todayLog.period()) {
            return CyclePhase.PERIOD;
        }
        // Si hoy se apuntó sin regla, ya no se da por supuesta aunque toque por la media.
        if (day <= period && (todayLog == null || todayLog.period())) {
            return CyclePhase.PERIOD;
        }
        int ovulation = cycle - 14;
        if (day < ovulation - OVULATION_WINDOW) {
            return CyclePhase.AFTER_PERIOD;
        }
        if (day <= ovulation + OVULATION_WINDOW) {
            return CyclePhase.MID_CYCLE;
        }
        return CyclePhase.BEFORE_PERIOD;
    }

    /** Primer día con regla tras un día sin ella (o sin apuntar). */
    static List<LocalDate> periodStarts(Map<LocalDate, CycleDay> byDate) {
        return byDate.values().stream()
                .filter(CycleDay::period)
                .map(CycleDay::date)
                .filter(d -> {
                    CycleDay before = byDate.get(d.minusDays(1));
                    return before == null || !before.period();
                })
                .sorted()
                .toList();
    }

    static int averageCycle(List<LocalDate> starts) {
        List<Long> lengths = new ArrayList<>();
        for (int i = 1; i < starts.size(); i++) {
            long length = ChronoUnit.DAYS.between(starts.get(i - 1), starts.get(i));
            if (length >= MIN_CYCLE && length <= MAX_CYCLE_ACCEPTED) {
                lengths.add(length);
            }
        }
        if (lengths.isEmpty()) {
            return DEFAULT_CYCLE;
        }
        List<Long> last = lengths.subList(Math.max(0, lengths.size() - CYCLES_FOR_AVERAGE), lengths.size());
        long average = Math.round(last.stream().mapToLong(Long::longValue).average().orElse(DEFAULT_CYCLE));
        return (int) Math.max(MIN_CYCLE, Math.min(MAX_CYCLE, average));
    }

    static int averagePeriod(Map<LocalDate, CycleDay> byDate, List<LocalDate> starts) {
        List<Integer> lengths = new ArrayList<>();
        for (LocalDate start : starts) {
            int length = 0;
            CycleDay d = byDate.get(start);
            while (d != null && d.period() && length < MAX_PERIOD_DAYS) {
                length++;
                d = byDate.get(start.plusDays(length));
            }
            lengths.add(length);
        }
        if (lengths.isEmpty()) {
            return DEFAULT_PERIOD;
        }
        long average = Math.round(lengths.stream().mapToInt(Integer::intValue).average().orElse(DEFAULT_PERIOD));
        return (int) Math.max(MIN_PERIOD, Math.min(MAX_PERIOD, average));
    }

    public boolean enabled() {
        return tracking.enabled();
    }

    public Instant consentedAt() {
        return tracking.consentedAt();
    }

    /** Cuándo se retiró el consentimiento al desactivarlo; nulo si sigue activo o nunca se dio. */
    public Instant withdrawnAt() {
        return tracking.withdrawnAt();
    }
}
