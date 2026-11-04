package com.synaptixfit.domain.port.output.training;

import com.synaptixfit.domain.model.training.CycleDay;
import com.synaptixfit.domain.model.training.CycleTracking;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/** Seguimiento del ciclo (opcional) y sus días apuntados; siempre por usuario. */
public interface CycleRepositoryPort {

    Optional<CycleTracking> findTracking(UUID userId);

    void saveTracking(UUID userId, CycleTracking tracking, Instant now);

    /** Días entre {@code from} y {@code to}, ambos incluidos. */
    List<CycleDay> findDays(UUID userId, LocalDate from, LocalDate to);

    Optional<CycleDay> findDay(UUID userId, LocalDate date);

    void saveDay(UUID userId, CycleDay day);

    void deleteDay(UUID userId, LocalDate date);

    void deleteAllDays(UUID userId);
}
