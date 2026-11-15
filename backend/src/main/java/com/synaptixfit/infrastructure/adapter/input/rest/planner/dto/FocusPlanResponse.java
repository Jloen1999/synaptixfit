package com.synaptixfit.infrastructure.adapter.input.rest.planner.dto;

import com.synaptixfit.domain.model.planner.FocusPlan;

/**
 * Duraciones recomendadas del Pomodoro de hoy y los límites para ajustarlas a mano: el bloque y, desde el ADR 0053,
 * también el descanso corto y el largo.
 */
public record FocusPlanResponse(int focusMinutes, int shortBreakMinutes, int longBreakMinutes,
                                int cyclesBeforeLongBreak, boolean limitedByFatigue, int minFocusMinutes,
                                int maxFocusMinutes, int minShortBreakMinutes, int maxShortBreakMinutes,
                                int minLongBreakMinutes, int maxLongBreakMinutes) {

    public static FocusPlanResponse from(FocusPlan p) {
        return new FocusPlanResponse(p.focusMinutes(), p.shortBreakMinutes(), p.longBreakMinutes(),
                p.cyclesBeforeLongBreak(), p.limitedByFatigue(), FocusPlan.MIN_FOCUS_MINUTES,
                FocusPlan.MAX_FOCUS_MINUTES, FocusPlan.MIN_SHORT_BREAK_MINUTES, FocusPlan.MAX_SHORT_BREAK_MINUTES,
                FocusPlan.MIN_LONG_BREAK_MINUTES, FocusPlan.MAX_LONG_BREAK_MINUTES);
    }
}
