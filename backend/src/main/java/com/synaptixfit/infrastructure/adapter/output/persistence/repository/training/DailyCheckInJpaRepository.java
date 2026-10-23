package com.synaptixfit.infrastructure.adapter.output.persistence.repository.training;

import com.synaptixfit.infrastructure.adapter.output.persistence.entity.training.DailyCheckInEntity;
import java.time.LocalDate;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

/** Spring Data para {@code estado_diario_usuario}. */
public interface DailyCheckInJpaRepository extends JpaRepository<DailyCheckInEntity, UUID> {

    Optional<DailyCheckInEntity> findByUsuarioIdAndFecha(UUID usuarioId, LocalDate fecha);

    Page<DailyCheckInEntity> findByUsuarioIdOrderByFechaDesc(UUID usuarioId, Pageable pageable);
}
