package com.synaptixfit.domain.model.academic;

import java.time.Instant;
import java.util.List;

/**
 * Conteo de materiales de una asignatura por estado de repaso (métricas de retención). «Necesita repaso» usa la misma
 * definición que la cola de repasos y «Ver N repasos pendientes» ({@link StudyMaterial#isDue}): su fecha SM-2 ya pasó,
 * esté como esté su dominio. El resto se reparte por {@link MasteryState}; uno fallado cuya fecha aún no ha llegado
 * cuenta «en progreso» (vocabulario.md §3: la misma cifra en todos los sitios).
 */
public record RetentionMetrics(int mastered, int inProgress, int needsReview, int notEvaluated, int abandoned,
                               int total) {

    public static RetentionMetrics of(List<StudyMaterial> materials, Instant now) {
        int mastered = 0;
        int inProgress = 0;
        int needsReview = 0;
        int notEvaluated = 0;
        int abandoned = 0;
        for (StudyMaterial m : materials) {
            if (m.masteryState() == MasteryState.ABANDONED) {
                abandoned++;
            } else if (m.isDue(now)) {
                needsReview++;
            } else {
                switch (m.masteryState()) {
                    case MASTERED -> mastered++;
                    case IN_PROGRESS, NEEDS_REVIEW -> inProgress++;
                    case NOT_EVALUATED -> notEvaluated++;
                    case ABANDONED -> abandoned++;
                }
            }
        }
        return new RetentionMetrics(mastered, inProgress, needsReview, notEvaluated, abandoned, materials.size());
    }
}
