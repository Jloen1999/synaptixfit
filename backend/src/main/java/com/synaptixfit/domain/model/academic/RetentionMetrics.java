package com.synaptixfit.domain.model.academic;

import java.util.List;

/** Conteo de materiales por estado de dominio (métricas de retención de una asignatura). */
public record RetentionMetrics(int mastered, int inProgress, int needsReview, int notEvaluated, int abandoned,
                               int total) {

    public static RetentionMetrics of(List<StudyMaterial> materials) {
        int mastered = 0;
        int inProgress = 0;
        int needsReview = 0;
        int notEvaluated = 0;
        int abandoned = 0;
        for (StudyMaterial m : materials) {
            switch (m.masteryState()) {
                case MASTERED -> mastered++;
                case IN_PROGRESS -> inProgress++;
                case NEEDS_REVIEW -> needsReview++;
                case NOT_EVALUATED -> notEvaluated++;
                case ABANDONED -> abandoned++;
            }
        }
        return new RetentionMetrics(mastered, inProgress, needsReview, notEvaluated, abandoned, materials.size());
    }
}
