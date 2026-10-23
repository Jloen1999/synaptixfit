package com.synaptixfit.domain.port.output.catalog;

import com.synaptixfit.domain.model.catalog.UserDegreeLink;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

/** Carreras vinculadas por cada usuario. */
public interface UserDegreeRepositoryPort {

    /** Vínculos del usuario, del más antiguo al más reciente. */
    List<UserDegreeLink> findByUser(UUID userId);

    boolean exists(UUID userId, UUID degreeId);

    void link(UUID userId, UUID degreeId, Instant when);

    void unlink(UUID userId, UUID degreeId);
}
