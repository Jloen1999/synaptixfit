package com.synaptixfit.application.port.input.together;

import com.synaptixfit.domain.model.together.StudyRoomReaction;
import java.util.UUID;

/** Pone (o cambia) mi reacción fija en la sala; se enseña durante unos minutos (ADR 0045). */
public interface ReactStudyRoomUseCase {

    StudyRoomView react(UUID userId, UUID roomId, StudyRoomReaction reaction);
}
