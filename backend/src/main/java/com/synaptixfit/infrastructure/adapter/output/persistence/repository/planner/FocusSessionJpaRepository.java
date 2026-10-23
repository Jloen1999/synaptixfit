package com.synaptixfit.infrastructure.adapter.output.persistence.repository.planner;

import com.synaptixfit.infrastructure.adapter.output.persistence.entity.planner.FocusSessionEntity;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

/** Spring Data para {@code sesiones_focus}. */
public interface FocusSessionJpaRepository extends JpaRepository<FocusSessionEntity, UUID> {

    List<FocusSessionEntity> findByUsuarioIdAndFechaBetweenOrderByCreadoEnAsc(UUID usuarioId, LocalDate from, LocalDate to);

    @Query("select coalesce(sum(f.xpOtorgado), 0) from FocusSessionEntity f where f.usuarioId = :userId and f.fecha = :date")
    int sumXpOtorgado(@Param("userId") UUID userId, @Param("date") LocalDate date);
}
