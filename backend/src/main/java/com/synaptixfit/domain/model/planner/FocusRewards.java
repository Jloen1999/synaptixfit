package com.synaptixfit.domain.model.planner;

import java.time.LocalDate;

/**
 * Experiencia del Pomodoro con tope diario anti-farmeo.
 *
 * <ul>
 *   <li>{@value #XP_PER_CYCLE} XP por ciclo de concentración de al menos {@value #MIN_CYCLE_MINUTES}
 *       minutos: la mitad de lo que da un bloque de 30 minutos, porque un Pomodoro suele hacerse
 *       dentro de un bloque que ya da su propia XP.</li>
 *   <li>Como mucho {@value #DAILY_CAP} XP al día (cuatro Pomodoros, una sesión clásica): el
 *       temporizador vive en el cliente y registrar fases sin estudiar no debe compensar.</li>
 *   <li>Solo se premia el día de hoy: registrar fases con fecha pasada no reabre topes ya cerrados.</li>
 * </ul>
 */
public final class FocusRewards {

    public static final int XP_PER_CYCLE = 5;
    public static final int MIN_CYCLE_MINUTES = 10;
    public static final int DAILY_CAP = 20;

    private FocusRewards() {
    }

    /** XP concedida y su motivo. */
    public record Reward(int xp, FocusXpStatus status) {
    }

    /**
     * @param alreadyAwardedToday XP de Pomodoro ya concedida hoy (suma guardada en el planificador)
     */
    public static Reward evaluate(FocusSession session, LocalDate today, int alreadyAwardedToday) {
        if (!session.isCompletedFocus() || !session.date().equals(today)) {
            return new Reward(0, FocusXpStatus.NOT_ELIGIBLE);
        }
        int eligibleCycles = Math.min(session.cycles(), session.durationMinutes() / MIN_CYCLE_MINUTES);
        if (eligibleCycles == 0) {
            return new Reward(0, FocusXpStatus.NOT_ELIGIBLE);
        }
        int remaining = Math.max(0, DAILY_CAP - Math.max(0, alreadyAwardedToday));
        int xp = Math.min(eligibleCycles * XP_PER_CYCLE, remaining);
        return new Reward(xp, xp > 0 ? FocusXpStatus.AWARDED : FocusXpStatus.DAILY_CAP_REACHED);
    }

    /** Solo la XP de {@link #evaluate}. */
    public static int xpFor(FocusSession session, LocalDate today, int alreadyAwardedToday) {
        return evaluate(session, today, alreadyAwardedToday).xp();
    }
}
