package com.synaptixfit.domain.port.output.planner;

import com.synaptixfit.domain.model.planner.CalendarFeed;
import java.util.Optional;
import java.util.UUID;

/** Suscripciones al calendario ({@code suscripciones_calendario}): una por usuario. */
public interface CalendarFeedRepositoryPort {

    /** Guarda la del usuario, sustituyendo la anterior si la había. */
    CalendarFeed save(CalendarFeed feed);

    Optional<CalendarFeed> findByUser(UUID userId);

    Optional<CalendarFeed> findByTokenHash(String tokenHash);

    void deleteByUser(UUID userId);
}
