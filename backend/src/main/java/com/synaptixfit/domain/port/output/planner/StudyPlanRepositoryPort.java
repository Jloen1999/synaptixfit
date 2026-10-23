package com.synaptixfit.domain.port.output.planner;

import com.synaptixfit.domain.model.planner.StudyPlan;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/** Persistencia de los planes semanales ({@code planes_estudio}). */
public interface StudyPlanRepositoryPort {

    StudyPlan save(StudyPlan plan);

    Optional<StudyPlan> findById(UUID id);

    Optional<StudyPlan> findByUserAndWeek(UUID userId, LocalDate weekStart);

    /** Página ordenada por semana descendente. */
    PageResult<StudyPlan> findByUser(UUID userId, PageRequest page);

    /** Planes del usuario compartidos con amigos o públicos. */
    List<StudyPlan> findNonPrivateByUser(UUID userId);

    void delete(UUID id);
}
