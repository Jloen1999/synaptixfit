package com.synaptixfit.infrastructure.adapter.output.persistence.repository.planner;

import com.synaptixfit.infrastructure.adapter.output.persistence.entity.planner.CalendarFeedEntity;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

/** Spring Data para {@code suscripciones_calendario}. */
public interface CalendarFeedJpaRepository extends JpaRepository<CalendarFeedEntity, UUID> {

    Optional<CalendarFeedEntity> findByTokenHash(String tokenHash);
}
