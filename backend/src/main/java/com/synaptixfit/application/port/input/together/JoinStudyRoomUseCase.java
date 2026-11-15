package com.synaptixfit.application.port.input.together;

import java.util.UUID;

/** Acepta la invitación a una sala o vuelve tras salir («Deshacer») mientras no haya terminado (ADR 0045). */
public interface JoinStudyRoomUseCase {

    StudyRoomView join(UUID userId, UUID roomId);
}
