package com.synaptixfit.infrastructure.adapter.input.rest.planner.dto;

import com.synaptixfit.domain.model.planner.FocusPlan;

/** Duraciones recomendadas del Pomodoro de hoy y los límites para ajustarlas a mano. */
public record FocusPlanResponse(int focusMinutes, int shortBreakMinutes, int longBreakMinutes,
                                int cyclesBeforeLongBreak, boolean limitedByFatigue, int minFocusMinutes,
                                int maxFocusMinutes) {

    public static FocusPlanResponse from(FocusPlan p) {
        return new FocusPlanResponse(p.focusMinutes(), p.shortBreakMinutes(), p.longBreakMinutes(),
                p.cyclesBeforeLongBreak(), p.limitedByFatigue(), FocusPlan.MIN_FOCUS_MINUTES,
                FocusPlan.MAX_FOCUS_MINUTES);
    }
}
