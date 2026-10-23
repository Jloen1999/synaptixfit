package com.synaptixfit.infrastructure.adapter.output.persistence.repository.training;

import com.synaptixfit.infrastructure.adapter.output.persistence.entity.training.SessionSetEntity;
import java.util.Collection;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

/** Spring Data para {@code series_sesion}. */
public interface SessionSetJpaRepository extends JpaRepository<SessionSetEntity, UUID> {

    List<SessionSetEntity> findBySesionIdIn(Collection<UUID> sesionIds);
}
