package com.synaptixfit.application.port.input.together;

import java.util.List;
import java.util.UUID;

/** Salas con rondas terminadas que aún no se han contado (las recorre el programador) (ADR 0045). */
public interface FindStudyRoomsToCreditUseCase {

    List<UUID> roomsToCredit();
}
