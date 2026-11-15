package com.synaptixfit.infrastructure.adapter.output.persistence.repository.badge;

import com.synaptixfit.infrastructure.adapter.output.persistence.entity.badge.StreakPauseEntity;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

/** Spring Data para {@code pausas_racha}. */
public interface StreakPauseJpaRepository extends JpaRepository<StreakPauseEntity, UUID> {

    List<StreakPauseEntity> findByUsuarioIdOrderByDesdeAsc(UUID usuarioId);
}
