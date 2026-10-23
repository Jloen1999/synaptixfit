package com.synaptixfit.domain.port.output.planner;

import com.synaptixfit.domain.model.planner.WeeklyAcademicLoad;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/** Persistencia de la carga académica semanal ({@code carga_academica_semanal}). */
public interface WeeklyLoadRepositoryPort {

    WeeklyAcademicLoad save(WeeklyAcademicLoad load);

    Optional<WeeklyAcademicLoad> findByUserAndWeek(UUID userId, LocalDate weekStart);

    /** Semanas con lunes en [fromWeek, toWeek], ordenadas ascendentemente. */
    List<WeeklyAcademicLoad> findByUserBetween(UUID userId, LocalDate fromWeek, LocalDate toWeek);
}
