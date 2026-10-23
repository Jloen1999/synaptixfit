package com.synaptixfit.infrastructure.adapter.output.persistence.repository.planner;

import com.synaptixfit.infrastructure.adapter.output.persistence.entity.planner.WeeklyLoadEntity;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

/** Spring Data para {@code carga_academica_semanal}. */
public interface WeeklyLoadJpaRepository extends JpaRepository<WeeklyLoadEntity, UUID> {

    Optional<WeeklyLoadEntity> findByUsuarioIdAndSemanaInicio(UUID usuarioId, LocalDate semanaInicio);

    List<WeeklyLoadEntity> findByUsuarioIdAndSemanaInicioBetweenOrderBySemanaInicioAsc(UUID usuarioId, LocalDate from,
                                                                                     LocalDate to);
}
