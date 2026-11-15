package com.synaptixfit.application.port.input.together;

import java.util.UUID;

/** Cuenta como Pomodoro las rondas terminadas de una sala a quien estaba dentro; devuelve cuántos apuntó (ADR 0045). */
public interface CreditStudyRoomRoundsUseCase {

    int creditRounds(UUID roomId);
}
