package com.synaptixfit.application.port.input.planner;

import java.time.Instant;
import java.util.UUID;

/**
 * Apunta una actividad física que ya pasó: crea un bloque de deporte en esa franja y lo marca completado con su
 * esfuerzo (experiencia, carga física y semana, como al completar cualquier bloque de deporte).
 */
public interface LogPastActivityUseCase {

    /**
     * @param title  qué fue («Fútbol»); opcional
     * @param effort esfuerzo percibido (1-10)
     */
    record Command(UUID userId, Instant start, int minutes, String title, int effort) {
    }

    SetBlockCompletionUseCase.Result logPastActivity(Command command);
}
