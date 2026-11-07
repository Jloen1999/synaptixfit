package com.synaptixfit.domain.port.output.planner;

import com.synaptixfit.domain.model.planner.ActivityKind;
import com.synaptixfit.domain.model.planner.ActivitySource;
import com.synaptixfit.domain.model.planner.LoggedSportActivity;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import java.time.Instant;
import java.util.UUID;

/** Detalles de las actividades apuntadas a mano (clase, minutos reales, distancia) y el deporte hecho. */
public interface LoggedActivityRepositoryPort {

    void save(UUID blockId, UUID userId, ActivityKind kind, int minutes, Integer distanceMeters, ActivitySource source,
              Instant now);

    /** Bloques de deporte completados del usuario, del más reciente al más antiguo, con sus detalles si los hay. */
    PageResult<LoggedSportActivity> findSportActivities(UUID userId, PageRequest page);
}
