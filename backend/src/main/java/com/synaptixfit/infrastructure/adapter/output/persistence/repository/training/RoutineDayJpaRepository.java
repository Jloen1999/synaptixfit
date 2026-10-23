package com.synaptixfit.infrastructure.adapter.output.persistence.repository.training;

import com.synaptixfit.infrastructure.adapter.output.persistence.entity.training.RoutineDayEntity;
import java.util.Collection;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

/** Spring Data para {@code dias_rutina}. */
public interface RoutineDayJpaRepository extends JpaRepository<RoutineDayEntity, UUID> {

    List<RoutineDayEntity> findBySemanaIdIn(Collection<UUID> semanaIds);
}
