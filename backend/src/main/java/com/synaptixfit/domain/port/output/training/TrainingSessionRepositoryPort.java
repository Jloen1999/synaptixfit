package com.synaptixfit.domain.port.output.training;

import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import com.synaptixfit.domain.model.training.TrainingSession;
import com.synaptixfit.domain.model.training.generation.CompletedSessionSummary;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/** Persistencia de sesiones de entrenamiento y sus series. */
public interface TrainingSessionRepositoryPort {

    TrainingSession save(TrainingSession session);

    Optional<TrainingSession> findById(UUID id);

    Optional<TrainingSession> findInProgressForDay(UUID userId, UUID dayId);

    /** Si hay otra sesión completada del día (distinta de {@code excludingSessionId}). */
    boolean existsCompletedForDay(UUID dayId, UUID excludingSessionId);

    /** Historial del usuario; {@code completed} nulo no filtra. Más recientes primero. */
    PageResult<TrainingSession> findByUser(UUID userId, Boolean completed, PageRequest page);

    Optional<Instant> lastCompletedAt(UUID userId);

    /** Últimas sesiones completadas con sus series y el ejercicio de cada serie. */
    List<CompletedSessionSummary> recentCompleted(UUID userId, int limit);

    int countCompletedBetween(UUID userId, Instant fromInclusive, Instant toExclusive);

    /** Sesiones completadas en el intervalo que dieron experiencia (para el tope diario). */
    int countRewardedBetween(UUID userId, Instant fromInclusive, Instant toExclusive);

    void delete(UUID sessionId);
}
