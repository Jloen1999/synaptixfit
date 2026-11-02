package com.synaptixfit.infrastructure.adapter.input.rest.academic.dto;

import com.synaptixfit.domain.model.academic.FlashcardsOutcome;
import com.synaptixfit.domain.model.academic.MasteryState;
import com.synaptixfit.domain.model.academic.ReviewOutcome;
import com.synaptixfit.domain.model.academic.ReviewPreview;
import com.synaptixfit.domain.model.academic.ReviewRecord;
import com.synaptixfit.domain.model.academic.StudyMaterial;
import com.synaptixfit.domain.model.academic.StudySourceType;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

/** DTOs de materiales de estudio y repaso espaciado. */
public final class MaterialDtos {

    private MaterialDtos() {
    }

    public record RegisterMaterialRequest(@NotNull StudySourceType originType, @NotNull UUID originId) {
    }

    public record StudyMaterialResponse(UUID id, UUID subjectId, StudySourceType originType, UUID originId,
                                        String title, MasteryState masteryState, Instant lastReviewedAt,
                                        Instant nextReviewAt, int intervalDays, double easeFactor,
                                        int completedReviews, int failedReviews, boolean practiceXpAwarded,
                                        Instant createdAt) {

        public static StudyMaterialResponse from(StudyMaterial m) {
            return new StudyMaterialResponse(m.id(), m.subjectId(), m.originType(), m.originId(), m.title(),
                    m.masteryState(), m.lastReviewedAt(), m.nextReviewAt(), m.intervalDays(),
                    Math.round(m.easeFactor() * 1000) / 1000.0, m.completedReviews(), m.failedReviews(),
                    m.practiceXpAwarded(), m.createdAt());
        }
    }

    /** Autoevaluación del repaso: 0 olvido total … 5 perfecto. */
    public record ReviewRequest(@NotNull @Min(0) @Max(5) Integer quality) {
    }

    public record ReviewRecordResponse(UUID id, Instant reviewedAt, int realQuality, double adjustedQuality,
                                       double fatigueCoefficient) {

        public static ReviewRecordResponse from(ReviewRecord r) {
            return new ReviewRecordResponse(r.id(), r.reviewedAt(), r.realQuality(), r.adjustedQuality(),
                    r.fatigueCoefficient());
        }
    }

    /** {@code xpAwarded}: XP del repaso (solo si tocaba: fecha SM-2 vencida o primer repaso). */
    public record ReviewResponse(StudyMaterialResponse material, ReviewRecordResponse review, int xpAwarded) {

        public static ReviewResponse from(ReviewOutcome o) {
            return new ReviewResponse(StudyMaterialResponse.from(o.material()), ReviewRecordResponse.from(o.record()),
                    o.xpAwarded());
        }
    }

    public record ReviewOptionResponse(int quality, double adjustedQuality, int intervalDays, Instant nextReviewAt,
                                       MasteryState resultingState) {
    }

    /** {@code practice}: práctica reciente y nota propuesta con ella (nula si no se practicó hace poco). */
    public record ReviewPreviewResponse(double loadToday, double maxDailyLoad, double fatigueCoefficient,
                                        List<ReviewOptionResponse> options, PracticeScoreResponse practice) {

        public static ReviewPreviewResponse from(ReviewPreview p) {
            return new ReviewPreviewResponse(p.loadToday(), p.maxDailyLoad(), p.fatigueCoefficient(),
                    p.options().stream().map(o -> new ReviewOptionResponse(o.quality(), o.adjustedQuality(),
                            o.intervalDays(), o.nextReviewAt(), o.resultingState())).toList(),
                    p.practice() == null ? null : new PracticeScoreResponse(p.practice().correct(),
                            p.practice().answered(), p.practice().suggestedQuality()));
        }
    }

    /** Práctica reciente con preguntas del material y la nota que se propone con ella (0-5). */
    public record PracticeScoreResponse(int correct, int answered, int suggestedQuality) {
    }

    public record FlashcardReviewRequest(@NotNull @Min(0) @Max(500) Integer mastered,
                                         @NotNull @Min(0) @Max(500) Integer doubtful,
                                         @NotNull @Min(0) @Max(500) Integer failed) {
    }

    public record FlashcardReviewResponse(StudyMaterialResponse material, ReviewRecordResponse review, int quality,
                                          int xpAwarded) {

        public static FlashcardReviewResponse from(FlashcardsOutcome o) {
            return new FlashcardReviewResponse(StudyMaterialResponse.from(o.material()),
                    ReviewRecordResponse.from(o.record()), o.quality(), o.xpAwarded());
        }
    }
}
