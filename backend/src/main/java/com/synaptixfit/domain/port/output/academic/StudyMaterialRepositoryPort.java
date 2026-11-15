package com.synaptixfit.domain.port.output.academic;

import com.synaptixfit.domain.model.academic.MasteryState;
import com.synaptixfit.domain.model.academic.ReviewLoadBalancer;
import com.synaptixfit.domain.model.academic.StudyMaterial;
import com.synaptixfit.domain.model.academic.StudySourceType;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/** Persistencia de materiales de estudio y su estado SM-2. */
public interface StudyMaterialRepositoryPort {

    Optional<StudyMaterial> findByIdAndUser(UUID id, UUID userId);

    Optional<StudyMaterial> findByOrigin(UUID userId, StudySourceType originType, UUID originId);

    /** Materiales del usuario (opcionalmente de una asignatura), los más recientes primero. */
    List<StudyMaterial> findByUser(UUID userId, UUID subjectId);

    /** Materiales con repaso vencido (siguiente repaso anterior o igual a {@code now}), el más antiguo primero. */
    List<StudyMaterial> findDue(UUID userId, Instant now, int limit);

    /**
     * Repasos programados entre {@code from} y {@code to} (para repartirlos sin picos, ADR 0042). La versión por
     * defecto filtra {@link #findByUser}; el adaptador lo hace con una consulta.
     */
    default List<ReviewLoadBalancer.Scheduled> scheduledReviews(UUID userId, Instant from, Instant to) {
        return findByUser(userId, null).stream()
                .filter(m -> m.masteryState() != MasteryState.ABANDONED && m.nextReviewAt() != null
                        && !m.nextReviewAt().isBefore(from) && m.nextReviewAt().isBefore(to))
                .map(m -> new ReviewLoadBalancer.Scheduled(m.id(), m.nextReviewAt()))
                .toList();
    }

    StudyMaterial save(StudyMaterial material);

    void delete(UUID id);
}
