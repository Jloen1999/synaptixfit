package com.synaptixfit.infrastructure.adapter.input.rest.together.dto;

import com.synaptixfit.application.port.input.together.TogetherLimits;
import com.synaptixfit.domain.model.together.StudyRoomLength;
import java.util.List;

/**
 * Topes de «Con amigos» para los selectores del cliente (ADR 0045): amigos por cosa, rachas, rondas y las duraciones de
 * ronda de una sala. El servidor manda y los vuelve a comprobar.
 */
public record TogetherLimitsResponse(int challengeFriends, int workoutFriends, int studyRoomFriends,
                                     int friendStreaks, int studyRoomRounds,
                                     List<StudyRoomLengthResponse> studyRoomLengths) {

    /** Una duración de ronda: {@code SHORT} 25 + 5 o {@code LONG} 50 + 10 minutos. */
    public record StudyRoomLengthResponse(StudyRoomLength length, int focusMinutes, int breakMinutes) {
    }

    public static TogetherLimitsResponse from(TogetherLimits l) {
        return new TogetherLimitsResponse(l.challengeFriends(), l.workoutFriends(), l.studyRoomFriends(),
                l.friendStreaks(), l.studyRoomRounds(), l.studyRoomLengths().stream()
                .map(o -> new StudyRoomLengthResponse(o.length(), o.focusMinutes(), o.breakMinutes()))
                .toList());
    }
}
