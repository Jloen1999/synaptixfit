package com.synaptixfit.application.port.input.badge;

import com.synaptixfit.domain.model.badge.StreakStatus;
import java.util.UUID;

/**
 * «Pausar racha» desde hoy (ADR 0042; sin motivo, solo fechas). Con una pausa en curso o sin racha no hace nada
 * (idempotente); sin días de pausa disponibles lanza {@code STREAK_PAUSE_LIMIT_REACHED}. Devuelve la racha ya en pausa.
 */
public interface PauseStreakUseCase {

    StreakStatus pause(UUID userId, String zone);
}
