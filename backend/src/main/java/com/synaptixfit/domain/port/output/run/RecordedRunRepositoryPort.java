package com.synaptixfit.domain.port.output.run;

import com.synaptixfit.domain.model.run.RecordedRun;
import com.synaptixfit.domain.model.run.RunDetail;
import com.synaptixfit.domain.model.run.RunWeek;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/** Carreras grabadas con el GPS ({@code carreras_gps}) y actividades de distancia de la semana. */
public interface RecordedRunRepositoryPort {

    /** Bloque de la carrera ya subida con esa clave del móvil (para no duplicarla al reintentar). */
    Optional<UUID> findBlockByClientKey(UUID userId, UUID clientKey);

    void save(RecordedRun run);

    /** @param routePoints como mucho cuántos puntos de la ruta se devuelven (repartidos por ella) */
    Optional<RunDetail> findDetail(UUID userId, UUID blockId, int routePoints);

    /** Actividades completadas que se miden en distancia (correr, andar, bici) que empezaron en [from, to). */
    List<RunWeek.Outing> findOutings(UUID userId, Instant from, Instant to);
}
