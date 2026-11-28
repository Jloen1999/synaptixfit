package com.synaptixfit.domain.port.output.planner;

import com.synaptixfit.domain.model.planner.ActivityKind;
import com.synaptixfit.domain.model.planner.ActivitySource;
import com.synaptixfit.domain.model.planner.LoggedSportActivity;
import com.synaptixfit.domain.model.planner.SportDetails;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import java.time.Instant;
import java.util.UUID;

/** Detalles de las actividades apuntadas a mano (clase, minutos reales, distancia) y el deporte hecho. */
public interface LoggedActivityRepositoryPort {

    /** Guarda o reemplaza la actividad del bloque; {@code sport} dice qué deporte fue y, si es un partido, cómo fue. */
    void save(UUID blockId, UUID userId, ActivityKind kind, SportDetails sport, int minutes, Integer distanceMeters,
              ActivitySource source, Instant now);

    /** Bloques de deporte completados del usuario, del más reciente al más antiguo, con sus detalles si los hay. */
    PageResult<LoggedSportActivity> findSportActivities(UUID userId, PageRequest page);
}
