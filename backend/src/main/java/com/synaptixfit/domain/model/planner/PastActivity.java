package com.synaptixfit.domain.model.planner;

import com.synaptixfit.domain.exception.FieldValidationException;
import com.synaptixfit.domain.exception.planner.PastActivityOutOfRangeException;
import com.synaptixfit.domain.exception.planner.PastActivityTypeNotAllowedException;
import com.synaptixfit.domain.model.shared.Guard;
import java.time.Duration;
import java.time.Instant;
import java.util.UUID;

/**
 * Actividad que ya pasó y se apunta después: deporte («ayer jugué al fútbol una hora», «salí a correr 5 km en
 * 28 min») o estudio («estudié Cálculo de 17:00 a 18:30 sin la app»). Se guarda como un bloque completado, así cuenta
 * como cualquier otro en la semana, la XP, la carga física (deporte, con su esfuerzo) o la carga cognitiva (estudio).
 *
 * <p>Solo de los últimos {@link #MAX_DAYS_BACK} días y ya terminada: más atrás la carga aguda y crónica (ACWR) y
 * la carga cognitiva del día ya no la usarían igual, y algo que aún no ha terminado se marca desde el
 * calendario. Solo deporte y estudio: clases, exámenes y entregas tienen su propio flujo, y descanso, comida y
 * sueño no se registran a posteriori.
 *
 * <p>Deporte desde {@value #MIN_SPORT_MINUTES} minutos (una carrera corta es deporte de verdad), con su clase
 * ({@link ActivityKind}) y, si se mide en distancia, los metros. Como un bloque del calendario dura al menos
 * {@link TimeRange#MIN_MINUTES} minutos, el bloque de una actividad más corta ocupa esos minutos acabando cuando
 * acabó la actividad; el ritmo se calcula con los minutos reales (ADR 0033).
 *
 * @param effort         esfuerzo percibido (1-10); obligatorio en deporte, se ignora en estudio
 * @param subjectId      asignatura del estudio (opcional); se ignora en deporte
 * @param kind           clase de deporte (por defecto {@link ActivityKind#OTHER}); nula en estudio
 * @param distanceMeters distancia, solo en clases que se miden así ({@link ActivityKind#measuresDistance()})
 * @param source         a mano o con el GPS de la app (ADR 0037): cambia cuántos días atrás se acepta
 */
public record PastActivity(Instant start, int minutes, String title, Integer effort, ActivityType type,
                           UUID subjectId, ActivityKind kind, Integer distanceMeters, ActivitySource source) {

    public static final int MAX_DAYS_BACK = 7;
    /** Como mucho 5 horas: más no es una sesión normal y descuadraría la carga. */
    public static final int MAX_MINUTES = 300;
    public static final int MIN_SPORT_MINUTES = 10;
    public static final int MIN_DISTANCE_METERS = 100;
    /** 300 km: de sobra para una salida en bici; más es un error al teclear. */
    public static final int MAX_DISTANCE_METERS = 300_000;

    public PastActivity {
        Guard.notNull(start, "start");
        source = source == null ? ActivitySource.MANUAL : source;
        type = type == null ? ActivityType.SPORT : type;
        if (type != ActivityType.SPORT && type != ActivityType.STUDY) {
            throw new PastActivityTypeNotAllowedException();
        }
        if (type == ActivityType.SPORT) {
            Guard.range(minutes, "minutes", MIN_SPORT_MINUTES, MAX_MINUTES);
            Guard.range(Guard.notNull(effort, "effort"), "effort", 1, 10);
            subjectId = null;
            kind = kind == null ? ActivityKind.OTHER : kind;
            if (!kind.measuresDistance()) {
                distanceMeters = null;
            } else if (distanceMeters != null
                    && (distanceMeters < MIN_DISTANCE_METERS || distanceMeters > MAX_DISTANCE_METERS)) {
                throw new FieldValidationException("distanceMeters", "OUT_OF_RANGE",
                        "distance must be between " + MIN_DISTANCE_METERS + " and " + MAX_DISTANCE_METERS + " m");
            }
        } else {
            Guard.range(minutes, "minutes", TimeRange.MIN_MINUTES, MAX_MINUTES);
            effort = null;
            kind = null;
            distanceMeters = null;
        }
        title = title == null || title.isBlank() ? null : title.strip();
        if (title != null && title.length() > CalendarBlock.TOPICS_MAX) {
            title = title.substring(0, CalendarBlock.TOPICS_MAX);
        }
    }

    public PastActivity(Instant start, int minutes, String title, Integer effort, ActivityType type,
                        UUID subjectId, ActivityKind kind, Integer distanceMeters) {
        this(start, minutes, title, effort, type, subjectId, kind, distanceMeters, ActivitySource.MANUAL);
    }

    public PastActivity(Instant start, int minutes, String title, Integer effort, ActivityType type, UUID subjectId) {
        this(start, minutes, title, effort, type, subjectId, null, null);
    }

    /** Actividad de deporte (la forma de antes, sin tipo). */
    public PastActivity(Instant start, int minutes, String title, int effort) {
        this(start, minutes, title, effort, ActivityType.SPORT, null);
    }

    /** Franja del bloque: la de la actividad, o la mínima de un bloque terminando cuando terminó. */
    public TimeRange range() {
        Instant end = end();
        long blockMinutes = Math.max(minutes, TimeRange.MIN_MINUTES);
        return new TimeRange(end.minus(Duration.ofMinutes(blockMinutes)), end);
    }

    public Instant end() {
        return start.plus(Duration.ofMinutes(minutes));
    }

    /**
     * Terminada y de los últimos {@link #MAX_DAYS_BACK} días si es a mano, o de los últimos 30 si se grabó con el GPS:
     * puede llegar tarde desde la cola de envíos del móvil (ADR 0037).
     */
    public void requireLoggableAt(Instant now) {
        if (end().isAfter(now) || start.isBefore(now.minus(Duration.ofDays(source.maxDaysBack())))) {
            throw new PastActivityOutOfRangeException();
        }
    }

    /** Ritmo y velocidad (solo deporte con distancia). */
    public ActivityPace pace() {
        return ActivityPace.of(minutes, distanceMeters);
    }
}
