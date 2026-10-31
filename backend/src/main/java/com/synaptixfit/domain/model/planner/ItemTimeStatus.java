package com.synaptixfit.domain.model.planner;

import java.time.Instant;

/**
 * Estado de un bloque o una entrega respecto a «ahora». La app distingue lo pendiente de lo que ya
 * pasó sin hacerse: un bloque de estudio, repaso, deporte o clase que terminó sin completarse queda
 * {@link #MISSED} (no hecho); una entrega sin completar cuya fecha pasó, también (vencida).
 */
public enum ItemTimeStatus {
    UPCOMING,
    IN_PROGRESS,
    DONE,
    /** Ya pasó y no se hizo (bloque) o venció sin completarse (entrega). */
    MISSED,
    /** Ya pasó y no tiene seguimiento (descanso, comida, sueño, examen o entrega en el calendario). */
    PAST;

    public static ItemTimeStatus ofBlock(ActivityType type, Instant start, Instant end, boolean completed,
                                         Instant now) {
        if (completed) {
            return DONE;
        }
        if (now.isBefore(start)) {
            return UPCOMING;
        }
        if (now.isBefore(end)) {
            return IN_PROGRESS;
        }
        return type.isTrackable() ? MISSED : PAST;
    }

    public static ItemTimeStatus ofDeadline(Instant dueAt, boolean completed, Instant now) {
        if (completed) {
            return DONE;
        }
        return dueAt.isBefore(now) ? MISSED : UPCOMING;
    }
}
