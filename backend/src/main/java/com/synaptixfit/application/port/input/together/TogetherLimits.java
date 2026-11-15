package com.synaptixfit.application.port.input.together;

import java.util.List;

/**
 * Topes de «Con amigos» (ADR 0044, 0045 y 0053) que el cliente necesita para limitar sus selectores sin repetirlos:
 * cuántos amigos se invitan a cada cosa, cuántas rachas con amigos puede tener una persona, cuántas rondas una sala,
 * entre cuántos minutos se eligen la concentración y el descanso de cada ronda y qué atajos se ofrecen.
 */
public record TogetherLimits(int challengeFriends, int workoutFriends, int studyRoomFriends, int friendStreaks,
                             int studyRoomRounds, Range studyRoomFocusMinutes, Range studyRoomBreakMinutes,
                             List<TimesOption> studyRoomPresets) {

    public TogetherLimits {
        studyRoomPresets = List.copyOf(studyRoomPresets);
    }

    /** Valores permitidos, ambos incluidos. */
    public record Range(int min, int max) {
    }

    /** Un atajo de ronda: minutos de concentración y del descanso que le sigue. */
    public record TimesOption(int focusMinutes, int breakMinutes) {
    }
}
