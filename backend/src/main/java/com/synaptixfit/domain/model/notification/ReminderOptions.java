package com.synaptixfit.domain.model.notification;

import com.synaptixfit.domain.exception.notification.ReminderOptionsInvalidException;
import java.time.LocalTime;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;
import java.util.Objects;
import java.util.Set;
import java.util.TreeSet;

/**
 * Avisos del móvil que la persona ajusta en Ajustes › Avisos (ADR 0033 y 0035): racha en riesgo, registro diario y
 * clase a punto de empezar (se apagan uno a uno), con cuánta antelación se avisa de eventos y clases, de entregas y
 * exámenes y de las tareas de reto, y a qué hora llega el resumen de la mañana (nula: apagado).
 *
 * <p>Las antelaciones son opciones cerradas para que la pantalla sea sencilla y el plan no pueda llenarse de avisos:
 * eventos y clases {@link #EVENT_LEAD_OPTIONS} minutos antes; entregas y exámenes, uno o varios de
 * {@link #DEADLINE_DAY_OPTIONS} días antes; el resumen, en punto o y media entre {@link #SUMMARY_EARLIEST} y
 * {@link #SUMMARY_LATEST}. Por defecto ({@link #DEFAULTS}) se avisa como antes de que se pudiera elegir: 15 minutos,
 * 3 días y 1 día.
 */
public record ReminderOptions(boolean streak, boolean checkIn, boolean classes, int eventLeadMinutes,
                              Set<Integer> deadlineDaysBefore, TaskTiming taskTiming, LocalTime morningSummaryAt) {

    public static final List<Integer> EVENT_LEAD_OPTIONS = List.of(5, 15, 30, 60);
    public static final List<Integer> DEADLINE_DAY_OPTIONS = List.of(1, 3, 7);
    public static final LocalTime SUMMARY_EARLIEST = LocalTime.of(5, 0);
    public static final LocalTime SUMMARY_LATEST = LocalTime.of(12, 0);
    public static final int DEFAULT_EVENT_LEAD_MINUTES = 15;
    public static final Set<Integer> DEFAULT_DEADLINE_DAYS = Set.of(1, 3);
    public static final LocalTime DEFAULT_SUMMARY_AT = LocalTime.of(8, 0);

    public static final ReminderOptions DEFAULTS = new ReminderOptions(true, true, true);

    /** Cuándo se avisa de una tarea de reto con fecha. */
    public enum TaskTiming {
        /** La tarde anterior, a la hora de los avisos de entregas. */
        EVENING_BEFORE,
        /** La mañana del día (en el resumen de la mañana si está encendido). */
        MORNING_OF
    }

    public ReminderOptions {
        if (!EVENT_LEAD_OPTIONS.contains(eventLeadMinutes)) {
            throw new ReminderOptionsInvalidException("eventLeadMinutes must be one of " + EVENT_LEAD_OPTIONS);
        }
        if (deadlineDaysBefore == null || deadlineDaysBefore.isEmpty()
                || !deadlineDaysBefore.stream().allMatch(d -> d != null && DEADLINE_DAY_OPTIONS.contains(d))) {
            throw new ReminderOptionsInvalidException("deadlineDaysBefore must be one or more of "
                    + DEADLINE_DAY_OPTIONS);
        }
        if (taskTiming == null) {
            throw new ReminderOptionsInvalidException("taskTiming is required");
        }
        if (morningSummaryAt != null && (morningSummaryAt.isBefore(SUMMARY_EARLIEST)
                || morningSummaryAt.isAfter(SUMMARY_LATEST) || morningSummaryAt.getMinute() % 30 != 0
                || morningSummaryAt.getSecond() != 0 || morningSummaryAt.getNano() != 0)) {
            throw new ReminderOptionsInvalidException("morningSummaryAt must be on the hour or half hour between "
                    + SUMMARY_EARLIEST + " and " + SUMMARY_LATEST);
        }
        // Ordenadas de más lejos a más cerca: así se recorren al planificar.
        TreeSet<Integer> sorted = new TreeSet<>(Comparator.reverseOrder());
        sorted.addAll(deadlineDaysBefore);
        deadlineDaysBefore = Collections.unmodifiableSortedSet(sorted);
    }

    /** Solo los interruptores; el resto, por defecto. */
    public ReminderOptions(boolean streak, boolean checkIn, boolean classes) {
        this(streak, checkIn, classes, DEFAULT_EVENT_LEAD_MINUTES, DEFAULT_DEADLINE_DAYS, TaskTiming.EVENING_BEFORE,
                DEFAULT_SUMMARY_AT);
    }

    /** ¿Llega el resumen de la mañana? */
    public boolean morningSummary() {
        return morningSummaryAt != null;
    }

    /**
     * Aplica un cambio parcial: lo que no viene se queda como estaba (una app antigua que solo conoce los
     * interruptores no borra las antelaciones elegidas).
     */
    public ReminderOptions with(Change change) {
        Objects.requireNonNull(change, "change");
        return new ReminderOptions(
                change.streak() == null ? streak : change.streak(),
                change.checkIn() == null ? checkIn : change.checkIn(),
                change.classes() == null ? classes : change.classes(),
                change.eventLeadMinutes() == null ? eventLeadMinutes : change.eventLeadMinutes(),
                change.deadlineDaysBefore() == null ? deadlineDaysBefore : change.deadlineDaysBefore(),
                change.taskTiming() == null ? taskTiming : change.taskTiming(),
                summaryAt(change));
    }

    /** Apagar gana; encender sin hora vuelve a la de siempre (o a la de por defecto); una hora nueva, esa. */
    private LocalTime summaryAt(Change change) {
        if (Boolean.FALSE.equals(change.morningSummary())) {
            return null;
        }
        if (change.morningSummaryAt() != null) {
            return change.morningSummaryAt();
        }
        if (Boolean.TRUE.equals(change.morningSummary()) && morningSummaryAt == null) {
            return DEFAULT_SUMMARY_AT;
        }
        return morningSummaryAt;
    }

    /**
     * Cambio parcial de las opciones; un campo nulo no cambia. {@code morningSummary}: {@code false} apaga el resumen
     * y {@code true} lo enciende (a {@code morningSummaryAt} o, sin hora, a la de antes o a las 8:00).
     */
    public record Change(Boolean streak, Boolean checkIn, Boolean classes, Integer eventLeadMinutes,
                         Set<Integer> deadlineDaysBefore, TaskTiming taskTiming, LocalTime morningSummaryAt,
                         Boolean morningSummary) {

        /** Solo los interruptores (lo que mandaba la app antes de ADR 0035). */
        public static Change switches(boolean streak, boolean checkIn, boolean classes) {
            return new Change(streak, checkIn, classes, null, null, null, null, null);
        }
    }
}
