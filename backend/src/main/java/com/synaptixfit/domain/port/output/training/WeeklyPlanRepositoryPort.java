package com.synaptixfit.domain.port.output.training;

import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import com.synaptixfit.domain.model.training.WeeklyTrainingPlan;
import java.time.LocalDate;
import java.util.Optional;
import java.util.UUID;

/** Persistencia de los planes semanales de entrenamiento. */
public interface WeeklyPlanRepositoryPort {

    Optional<WeeklyTrainingPlan> findByUserAndWeek(UUID userId, LocalDate weekStart);

    WeeklyTrainingPlan save(WeeklyTrainingPlan plan);

    void delete(UUID planId);

    /** Semanas más recientes primero. */
    PageResult<WeeklyTrainingPlan> findByUser(UUID userId, PageRequest page);
}
