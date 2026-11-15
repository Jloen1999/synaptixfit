package com.synaptixfit.infrastructure.adapter.input.rest.together.dto;

import com.synaptixfit.application.port.input.together.TogetherLimits;
import java.util.List;

/**
 * Topes de «Con amigos» para los selectores del cliente (ADR 0045 y 0053): amigos por cosa, rachas, rondas, entre
 * cuántos minutos se eligen la concentración y el descanso de una sala y los atajos (25 + 5 y 50 + 10). El servidor
 * manda y los vuelve a comprobar.
 */
public record TogetherLimitsResponse(int challengeFriends, int workoutFriends, int studyRoomFriends,
                                     int friendStreaks, int studyRoomRounds, RangeResponse studyRoomFocusMinutes,
                                     RangeResponse studyRoomBreakMinutes,
                                     List<StudyRoomPresetResponse> studyRoomPresets) {

    /** Valores permitidos, ambos incluidos. */
    public record RangeResponse(int min, int max) {
    }

    /** Un atajo de ronda: minutos de concentración y del descanso que le sigue. */
    public record StudyRoomPresetResponse(int focusMinutes, int breakMinutes) {
    }

    public static TogetherLimitsResponse from(TogetherLimits l) {
        return new TogetherLimitsResponse(l.challengeFriends(), l.workoutFriends(), l.studyRoomFriends(),
                l.friendStreaks(), l.studyRoomRounds(),
                new RangeResponse(l.studyRoomFocusMinutes().min(), l.studyRoomFocusMinutes().max()),
                new RangeResponse(l.studyRoomBreakMinutes().min(), l.studyRoomBreakMinutes().max()),
                l.studyRoomPresets().stream()
                        .map(o -> new StudyRoomPresetResponse(o.focusMinutes(), o.breakMinutes()))
                        .toList());
    }
}
