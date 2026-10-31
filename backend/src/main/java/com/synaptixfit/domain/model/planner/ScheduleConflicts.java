package com.synaptixfit.domain.model.planner;

import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Detección de solapes entre bloques y búsqueda de huecos libres.
 *
 * <p>Un solape no impide guardar un bloque (el lienzo permite colocar libremente): se marca
 * {@code tiene_conflicto} en los bloques implicados y se devuelve al cliente como aviso.
 */
public final class ScheduleConflicts {

    private static final Duration STEP = Duration.ofMinutes(30);

    private ScheduleConflicts() {
    }

    /** Bloques de {@code others} que se solapan con {@code range}, excluyendo {@code excludeId}. */
    public static List<CalendarBlock> overlapping(TimeRange range, Collection<CalendarBlock> others, UUID excludeId) {
        List<CalendarBlock> result = new ArrayList<>();
        for (CalendarBlock other : others) {
            if (!other.id().equals(excludeId) && range.overlaps(other.range())) {
                result.add(other);
            }
        }
        return result;
    }

    /**
     * Recalcula la marca de conflicto de cada bloque frente al resto de la lista.
     *
     * @return los bloques cuya marca ha cambiado (para guardarlos)
     */
    public static List<CalendarBlock> refreshFlags(List<CalendarBlock> blocks) {
        List<CalendarBlock> changed = new ArrayList<>();
        for (CalendarBlock block : blocks) {
            boolean conflict = !overlapping(block.range(), blocks, block.id()).isEmpty();
            if (conflict != block.hasConflict()) {
                block.flagConflict(conflict);
                changed.add(block);
            }
        }
        return changed;
    }

    /** Pares de bloques solapados (cada par una vez, ordenados por inicio). */
    public static List<Pair> pairs(List<CalendarBlock> blocks) {
        List<CalendarBlock> sorted = blocks.stream()
                .sorted((a, b) -> a.start().compareTo(b.start())).toList();
        List<Pair> pairs = new ArrayList<>();
        for (int i = 0; i < sorted.size(); i++) {
            for (int j = i + 1; j < sorted.size(); j++) {
                CalendarBlock a = sorted.get(i);
                CalendarBlock b = sorted.get(j);
                if (!b.start().isBefore(a.end())) {
                    break;
                }
                if (a.range().overlaps(b.range())) {
                    pairs.add(new Pair(a, b));
                }
            }
        }
        return pairs;
    }

    /**
     * Primer hueco libre de {@code minutes} minutos que empieza en {@code from} o después (alineado a
     * medias horas) y termina como tarde en {@code until}.
     */
    public static Optional<TimeRange> firstFreeSlot(long minutes, Instant from, Instant until,
                                                    Collection<CalendarBlock> busy) {
        Instant candidate = alignToHalfHour(from);
        while (!candidate.plus(Duration.ofMinutes(minutes)).isAfter(until)) {
            TimeRange slot = TimeRange.ofMinutes(candidate, minutes);
            if (overlapping(slot, busy, null).isEmpty()) {
                return Optional.of(slot);
            }
            candidate = candidate.plus(STEP);
        }
        return Optional.empty();
    }

    /** Horas del día en las que se busca hueco para reprogramar (ni de madrugada ni de noche). */
    public static final LocalTime RESCHEDULE_DAY_START = LocalTime.of(8, 0);
    public static final LocalTime RESCHEDULE_DAY_END = LocalTime.of(22, 0);
    public static final int RESCHEDULE_DAYS_AHEAD = 7;

    /**
     * Primer hueco libre de {@code minutes} desde {@code now}, día a día entre las 8:00 y las 22:00
     * de la zona del planificador, en los próximos {@link #RESCHEDULE_DAYS_AHEAD} días.
     */
    public static Optional<TimeRange> nextFreeSlot(long minutes, Instant now, PlannerZone zone,
                                                   Collection<CalendarBlock> busy) {
        LocalDate today = zone.today(now);
        for (int d = 0; d < RESCHEDULE_DAYS_AHEAD; d++) {
            LocalDate day = today.plusDays(d);
            Instant dayStart = zone.at(day, RESCHEDULE_DAY_START);
            Instant from = dayStart.isBefore(now) ? now : dayStart;
            Optional<TimeRange> slot = firstFreeSlot(minutes, from, zone.at(day, RESCHEDULE_DAY_END), busy);
            if (slot.isPresent()) {
                return slot;
            }
        }
        return Optional.empty();
    }

    /** Redondea hacia arriba a la siguiente media hora en punto (xx:00 o xx:30 UTC). */
    public static Instant alignToHalfHour(Instant instant) {
        Instant truncated = instant.truncatedTo(ChronoUnit.MINUTES);
        long minuteOfHour = (truncated.getEpochSecond() / 60) % 60;
        long remainder = minuteOfHour % 30;
        if (remainder == 0 && truncated.equals(instant)) {
            return truncated;
        }
        return truncated.plus(Duration.ofMinutes(30 - remainder));
    }

    /** Dos bloques que se solapan. */
    public record Pair(CalendarBlock first, CalendarBlock second) {
    }
}
