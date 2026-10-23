package com.synaptixfit.infrastructure.adapter.output.persistence.repository.profile;

import com.synaptixfit.infrastructure.adapter.output.persistence.entity.profile.GoalHistoryEntity;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

/** Spring Data para {@code historial_objetivos}. */
public interface GoalHistoryJpaRepository extends JpaRepository<GoalHistoryEntity, UUID> {

    Optional<GoalHistoryEntity> findFirstByUsuarioIdAndFechaFinIsNullOrderByFechaInicioDescCreadoEnDesc(UUID usuarioId);

    List<GoalHistoryEntity> findByUsuarioIdOrderByFechaInicioDescCreadoEnDesc(UUID usuarioId);
}
