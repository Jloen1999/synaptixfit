package com.synaptixfit.infrastructure.adapter.output.persistence.repository.profile;

import com.synaptixfit.infrastructure.adapter.output.persistence.entity.profile.WeightHistoryEntity;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

/** Spring Data para {@code historial_peso}. */
public interface WeightHistoryJpaRepository extends JpaRepository<WeightHistoryEntity, UUID> {

    List<WeightHistoryEntity> findByUsuarioIdAndRegistradoEnGreaterThanEqualAndRegistradoEnLessThanOrderByRegistradoEnAsc(
            UUID usuarioId, Instant from, Instant to);
}
