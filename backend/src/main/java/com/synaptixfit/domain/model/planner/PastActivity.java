package com.synaptixfit.domain.model.planner;

import com.synaptixfit.domain.exception.planner.PastActivityOutOfRangeException;
import com.synaptixfit.domain.model.shared.Guard;
import java.time.Duration;
import java.time.Instant;

/**
 * Actividad física que ya pasó y se apunta después («ayer jugué al fútbol una hora»). Se guarda como un bloque
 * de deporte completado, con su esfuerzo, para que cuente en la carga física y en la semana.
 *
 * <p>Solo de los últimos {@link #MAX_DAYS_BACK} días y ya terminada: más atrás la carga aguda y crónica (ACWR) ya
 * no la usaría igual, y algo que aún no ha terminado se marca desde el calendario.
 */
public record PastActivity(Instant start, int minutes, String title, int effort) {

    public static final int MAX_DAYS_BACK = 7;
    /** Como mucho 5 horas: más no es una sesión normal y descuadraría la carga. */
    public static final int MAX_MINUTES = 300;

    public PastActivity {
        Guard.notNull(start, "start");
        Guard.range(minutes, "minutes", TimeRange.MIN_MINUTES, MAX_MINUTES);
        Guard.range(effort, "effort", 1, 10);
        title = title == null || title.isBlank() ? null : title.strip();
        if (title != null && title.length() > CalendarBlock.TOPICS_MAX) {
            title = title.substring(0, CalendarBlock.TOPICS_MAX);
        }
    }

    public TimeRange range() {
        return new TimeRange(start, start.plus(Duration.ofMinutes(minutes)));
    }

    /** Terminada y de los últimos {@link #MAX_DAYS_BACK} días. */
    public void requireLoggableAt(Instant now) {
        Instant end = start.plus(Duration.ofMinutes(minutes));
        if (end.isAfter(now) || start.isBefore(now.minus(Duration.ofDays(MAX_DAYS_BACK)))) {
            throw new PastActivityOutOfRangeException();
        }
    }
}
