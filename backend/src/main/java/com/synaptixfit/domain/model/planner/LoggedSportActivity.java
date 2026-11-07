package com.synaptixfit.domain.model.planner;

import java.time.Instant;
import java.util.UUID;

/**
 * Deporte hecho fuera de las sesiones de rutina (un partido marcado en el calendario o una actividad apuntada a
 * mano), para el historial de entrenos. Los minutos son los reales si se apuntaron; si no, los del bloque.
 *
 * @param kind   clase de deporte; nula si se marcó desde el calendario sin apuntarla a mano
 * @param effort esfuerzo percibido (1-10) si se registró
 * @param source a mano o con el GPS de la app; nulo si se marcó desde el calendario sin apuntarla
 * @param elevationGainMeters desnivel positivo de una carrera grabada con GPS (nulo en las demás)
 */
public record LoggedSportActivity(UUID blockId, Instant start, int minutes, String title, ActivityKind kind,
                                  Integer distanceMeters, Integer effort, ActivitySource source,
                                  Integer elevationGainMeters) {

    public ActivityPace pace() {
        return ActivityPace.of(minutes, distanceMeters);
    }
}
