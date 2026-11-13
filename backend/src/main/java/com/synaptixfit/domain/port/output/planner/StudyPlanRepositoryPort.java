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

    /**
     * Plan de la semana de {@code plan}: el que ya hubiera o {@code plan}, recién creado. Si otra petición lo crea a
     * la vez no falla (índice único por usuario y semana): devuelve el suyo.
     */
    StudyPlan saveIfAbsent(StudyPlan plan);

    /**
     * Anota que el plan ya dio {@code points} de experiencia, solo si aún no la había dado. Devuelve {@code true}
     * únicamente a la llamada que la anota: de dos peticiones a la vez, solo una puede darla.
     */
    boolean markExperienceAwarded(UUID planId, int points);

    Optional<StudyPlan> findById(UUID id);

    Optional<StudyPlan> findByUserAndWeek(UUID userId, LocalDate weekStart);

    /** Página ordenada por semana descendente. */
    PageResult<StudyPlan> findByUser(UUID userId, PageRequest page);

    /** Planes del usuario compartidos con amigos o públicos. */
    List<StudyPlan> findNonPrivateByUser(UUID userId);

    void delete(UUID id);
}
