package com.synaptixfit.domain.model.together;

import com.synaptixfit.domain.model.planner.FocusPlan;
import com.synaptixfit.domain.model.shared.Guard;
import java.util.List;

/**
 * Minutos de cada ronda de «Estudiamos juntos» (ADR 0045 y 0053): concentración y el descanso que le sigue. Se eligen
 * libremente dentro de los límites; 25 + 5 y 50 + 10 son los atajos de siempre.
 *
 * <p>Los límites son los del Pomodoro individual ({@link FocusPlan}), así no pueden separarse: concentración de 15 a
 * 90 min y descanso de 1 a 30 min (más de media hora ya no es un descanso entre rondas).
 */
public record StudyRoomTimes(int focusMinutes, int breakMinutes) {

    public static final int MIN_FOCUS_MINUTES = FocusPlan.MIN_FOCUS_MINUTES;
    public static final int MAX_FOCUS_MINUTES = FocusPlan.MAX_FOCUS_MINUTES;
    public static final int MIN_BREAK_MINUTES = FocusPlan.MIN_SHORT_BREAK_MINUTES;
    public static final int MAX_BREAK_MINUTES = FocusPlan.MAX_SHORT_BREAK_MINUTES;

    /** El Pomodoro clásico. */
    public static final StudyRoomTimes SHORT = new StudyRoomTimes(25, 5);
    /** Bloques largos, cerca del ciclo de atención de 52/17. */
    public static final StudyRoomTimes LONG = new StudyRoomTimes(50, 10);
    /** Atajos que ofrece la app; cualquier otra combinación dentro de los límites vale igual. */
    public static final List<StudyRoomTimes> PRESETS = List.of(SHORT, LONG);

    public StudyRoomTimes {
        Guard.range(focusMinutes, "focusMinutes", MIN_FOCUS_MINUTES, MAX_FOCUS_MINUTES);
        Guard.range(breakMinutes, "breakMinutes", MIN_BREAK_MINUTES, MAX_BREAK_MINUTES);
    }
}
