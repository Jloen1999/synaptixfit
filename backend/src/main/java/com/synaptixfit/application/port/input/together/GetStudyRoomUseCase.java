package com.synaptixfit.application.port.input.together;

import java.util.UUID;

/** Una sala en la que la persona está invitada o dentro (ADR 0045). */
public interface GetStudyRoomUseCase {

    StudyRoomView get(UUID userId, UUID roomId);
}
