package com.synaptixfit.domain.port.output.profile;

import com.synaptixfit.domain.model.profile.WeightRecord;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

/** Historial de peso. */
public interface WeightHistoryRepositoryPort {

    WeightRecord append(WeightRecord record);

    /** Registros del usuario en [from, to), del más antiguo al más reciente. */
    List<WeightRecord> findByUser(UUID userId, Instant fromInclusive, Instant toExclusive);
}
