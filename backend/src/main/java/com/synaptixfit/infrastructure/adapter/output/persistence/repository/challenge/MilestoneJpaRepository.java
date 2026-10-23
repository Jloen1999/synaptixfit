package com.synaptixfit.infrastructure.adapter.output.persistence.repository.challenge;

import com.synaptixfit.infrastructure.adapter.output.persistence.entity.challenge.MilestoneEntity;
import java.util.Collection;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

/** Spring Data para {@code hitos_de_reto}. */
public interface MilestoneJpaRepository extends JpaRepository<MilestoneEntity, UUID> {

    List<MilestoneEntity> findByRetoIdOrderByIndiceOrdenAsc(UUID retoId);

    List<MilestoneEntity> findByRetoIdIn(Collection<UUID> retoIds);
}
