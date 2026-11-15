package com.synaptixfit.application.port.input.together;

import java.util.UUID;

/** Sale de la sala; los demás siguen. Antes se cuentan las rondas ya terminadas (ADR 0045). */
public interface LeaveStudyRoomUseCase {

    void leave(UUID userId, UUID roomId);
}
