package com.synaptixfit.domain.model.dashboard;

import com.synaptixfit.domain.model.dashboard.Dashboard.PlanDay;
import java.util.List;

/**
 * «Tu semana» en una frase (ADR 0059): cuántas cosas hay hechas de las planificadas, cuántas se quedaron sin hacer y
 * cómo vas. Sale de los mismos días que {@link Dashboard#planWeek()}, así la frase y los círculos nunca se contradicen.
 */
public record WeekSummary(int done, int planned, int missed, State state) {

    /**
     * Vas por detrás cuando más de una de cada cuatro cosas que ya tocaban se quedó sin hacer: una sola falta en una
     * semana cargada no es ir mal, y la mitad sin hacer sí. Lo que aún no toca no cuenta.
     */
    static final double BEHIND_SHARE = 0.25;

    /** Cómo va la semana. */
    public enum State {
        /** Nada planificado esta semana (sin descansos, comidas ni sueño). */
        NO_PLAN,
        /** Lo que ya tocaba está hecho casi todo. */
        ON_TRACK,
        /** Se quedó sin hacer más de lo razonable ({@link #BEHIND_SHARE}). */
        BEHIND
    }

    public static WeekSummary of(List<PlanDay> days) {
        int planned = days.stream().mapToInt(PlanDay::planned).sum();
        int done = days.stream().mapToInt(PlanDay::completed).sum();
        int missed = days.stream().mapToInt(PlanDay::missed).sum();
        if (planned == 0) {
            return new WeekSummary(0, 0, 0, State.NO_PLAN);
        }
        int due = done + missed;
        boolean behind = due > 0 && missed > due * BEHIND_SHARE;
        return new WeekSummary(done, planned, missed, behind ? State.BEHIND : State.ON_TRACK);
    }
}
