package com.synaptixfit.domain.model.planner;

import com.synaptixfit.domain.exception.planner.InvalidBlockTimeRangeException;
import com.synaptixfit.domain.model.shared.Guard;
import java.time.Duration;
import java.time.Instant;

/**
 * Franja horaria de un bloque: el fin es posterior al inicio y dura al menos
 * {@link #MIN_MINUTES} minutos (la misma regla que el CHECK de la tabla).
 */
public record TimeRange(Instant start, Instant end) {

    public static final int MIN_MINUTES = 30;

    public TimeRange {
        Guard.notNull(start, "start");
        Guard.notNull(end, "end");
        if (!end.isAfter(start) || Duration.between(start, end).toMinutes() < MIN_MINUTES) {
            throw new InvalidBlockTimeRangeException();
        }
    }

    public static TimeRange ofMinutes(Instant start, long minutes) {
        return new TimeRange(start, start.plus(Duration.ofMinutes(minutes)));
    }

    public long minutes() {
        return Duration.between(start, end).toMinutes();
    }

    public long seconds() {
        return Duration.between(start, end).toSeconds();
    }

    /** Solape estricto: dos franjas contiguas (una termina cuando empieza la otra) no se solapan. */
    public boolean overlaps(Instant otherStart, Instant otherEnd) {
        return start.isBefore(otherEnd) && otherStart.isBefore(end);
    }

    public boolean overlaps(TimeRange other) {
        return overlaps(other.start, other.end);
    }

    public TimeRange shiftTo(Instant newStart) {
        return ofMinutes(newStart, minutes());
    }
}
