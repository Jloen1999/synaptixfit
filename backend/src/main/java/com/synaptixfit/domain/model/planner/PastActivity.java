package com.synaptixfit.domain.model.planner;

import com.synaptixfit.domain.exception.planner.PastActivityOutOfRangeException;
import com.synaptixfit.domain.exception.planner.PastActivityTypeNotAllowedException;
import com.synaptixfit.domain.model.shared.Guard;
import java.time.Duration;
import java.time.Instant;
import java.util.UUID;

/**
 * Actividad que ya pasó y se apunta después: deporte («ayer jugué al fútbol una hora») o estudio («estudié
 * Cálculo de 17:00 a 18:30 sin la app»). Se guarda como un bloque completado, así cuenta como cualquier otro
 * en la semana, la XP, la carga física (deporte, con su esfuerzo) o la carga cognitiva (estudio).
 *
 * <p>Solo de los últimos {@link #MAX_DAYS_BACK} días y ya terminada: más atrás la carga aguda y crónica (ACWR) y
 * la carga cognitiva del día ya no la usarían igual, y algo que aún no ha terminado se marca desde el
 * calendario. Solo deporte y estudio: clases, exámenes y entregas tienen su propio flujo, y descanso, comida y
 * sueño no se registran a posteriori.
 *
 * @param effort    esfuerzo percibido (1-10); obligatorio en deporte, se ignora en estudio
 * @param subjectId asignatura del estudio (opcional); se ignora en deporte
 */
public record PastActivity(Instant start, int minutes, String title, Integer effort, ActivityType type,
                           UUID subjectId) {

    public static final int MAX_DAYS_BACK = 7;
    /** Como mucho 5 horas: más no es una sesión normal y descuadraría la carga. */
    public static final int MAX_MINUTES = 300;

    public PastActivity {
        Guard.notNull(start, "start");
        type = type == null ? ActivityType.SPORT : type;
        if (type != ActivityType.SPORT && type != ActivityType.STUDY) {
            throw new PastActivityTypeNotAllowedException();
        }
        Guard.range(minutes, "minutes", TimeRange.MIN_MINUTES, MAX_MINUTES);
        if (type == ActivityType.SPORT) {
            Guard.range(Guard.notNull(effort, "effort"), "effort", 1, 10);
            subjectId = null;
        } else {
            effort = null;
        }
        title = title == null || title.isBlank() ? null : title.strip();
        if (title != null && title.length() > CalendarBlock.TOPICS_MAX) {
            title = title.substring(0, CalendarBlock.TOPICS_MAX);
        }
    }

    /** Actividad de deporte (la forma de antes, sin tipo). */
    public PastActivity(Instant start, int minutes, String title, int effort) {
        this(start, minutes, title, effort, ActivityType.SPORT, null);
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
