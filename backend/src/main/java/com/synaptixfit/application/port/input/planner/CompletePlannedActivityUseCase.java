package com.synaptixfit.application.port.input.planner;

import com.synaptixfit.domain.model.planner.ActivityKind;
import com.synaptixfit.domain.model.planner.ActivitySource;
import java.util.UUID;

/**
 * Deja hecho como actividad un evento de deporte ya empezado (p. ej. un entreno de carrera grabado con el GPS, ADR
 * 0037): lo completa con su esfuerzo (XP, carga física, retos y semana, como al marcarlo en el calendario) y guarda
 * su clase, minutos reales, distancia y origen, para que salga en «Actividades y partidos» con su ritmo.
 */
public interface CompletePlannedActivityUseCase {

    /**
     * @param effort  esfuerzo percibido (1-10)
     * @param minutes minutos reales de la actividad
     */
    record Command(UUID userId, UUID blockId, int effort, ActivityKind kind, int minutes, Integer distanceMeters,
                   ActivitySource source) {
    }

    SetBlockCompletionUseCase.Result completePlannedActivity(Command command);
}
