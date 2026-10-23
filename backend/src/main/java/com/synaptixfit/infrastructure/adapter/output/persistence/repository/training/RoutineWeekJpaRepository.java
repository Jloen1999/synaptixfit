package com.synaptixfit.infrastructure.adapter.output.persistence.repository.training;

import com.synaptixfit.infrastructure.adapter.output.persistence.entity.training.RoutineWeekEntity;
import java.util.Collection;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

/** Spring Data para {@code semanas_rutina}. */
public interface RoutineWeekJpaRepository extends JpaRepository<RoutineWeekEntity, UUID> {

    List<RoutineWeekEntity> findByRutinaIdIn(Collection<UUID> rutinaIds);
}
