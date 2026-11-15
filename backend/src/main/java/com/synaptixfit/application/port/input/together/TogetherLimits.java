package com.synaptixfit.application.port.input.together;

import com.synaptixfit.domain.model.together.StudyRoomLength;
import java.util.List;

/**
 * Topes de «Con amigos» (ADR 0044 y 0045) que el cliente necesita para limitar sus selectores sin repetirlos:
 * cuántos amigos se invitan a cada cosa, cuántas rachas con amigos puede tener una persona, cuántas rondas una sala y
 * cuánto dura cada ronda.
 */
public record TogetherLimits(int challengeFriends, int workoutFriends, int studyRoomFriends, int friendStreaks,
                             int studyRoomRounds, List<LengthOption> studyRoomLengths) {

    public TogetherLimits {
        studyRoomLengths = List.copyOf(studyRoomLengths);
    }

    /** Una duración de ronda: minutos de concentración y del descanso que le sigue. */
    public record LengthOption(StudyRoomLength length, int focusMinutes, int breakMinutes) {
    }
}
