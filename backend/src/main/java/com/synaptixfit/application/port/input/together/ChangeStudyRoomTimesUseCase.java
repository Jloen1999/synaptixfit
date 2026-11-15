package com.synaptixfit.application.port.input.together;

import com.synaptixfit.domain.model.together.StudyRoomTimes;
import java.util.UUID;

/**
 * Cambia los minutos de concentración y de descanso de una sala que aún no ha empezado; vale cualquiera que esté
 * dentro y se avisa en directo a los demás (ADR 0053).
 */
public interface ChangeStudyRoomTimesUseCase {

    StudyRoomView changeTimes(UUID userId, UUID roomId, StudyRoomTimes times);
}
