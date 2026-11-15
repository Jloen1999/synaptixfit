package com.synaptixfit.application.port.input.together;

import java.util.UUID;

/** Empieza el temporizador común; vale cualquiera que esté dentro y solo una vez (ADR 0045). */
public interface StartStudyRoomUseCase {

    StudyRoomView start(UUID userId, UUID roomId);
}
