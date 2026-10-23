package com.synaptixfit.infrastructure.adapter.output.persistence.repository.planner;

import com.synaptixfit.infrastructure.adapter.output.persistence.entity.planner.DeadlineEntity;
import java.util.Collection;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;

/** Spring Data para {@code entregas_examenes}. */
public interface DeadlineJpaRepository extends JpaRepository<DeadlineEntity, UUID>,
        JpaSpecificationExecutor<DeadlineEntity> {

    List<DeadlineEntity> findByUsuarioIdAndIcsUidIn(UUID usuarioId, Collection<String> icsUids);
}
