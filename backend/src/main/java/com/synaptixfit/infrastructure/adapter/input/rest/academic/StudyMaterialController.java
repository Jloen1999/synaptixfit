package com.synaptixfit.infrastructure.adapter.input.rest.academic;

import com.synaptixfit.application.port.input.academic.DeleteStudyMaterialUseCase;
import com.synaptixfit.application.port.input.academic.GetRetentionMetricsUseCase;
import com.synaptixfit.application.port.input.academic.GetStudyMaterialUseCase;
import com.synaptixfit.application.port.input.academic.ListDueStudyMaterialsUseCase;
import com.synaptixfit.application.port.input.academic.ListReviewHistoryUseCase;
import com.synaptixfit.application.port.input.academic.ListStudyMaterialsUseCase;
import com.synaptixfit.application.port.input.academic.PreviewReviewIntervalsUseCase;
import com.synaptixfit.application.port.input.academic.RegisterStudyMaterialUseCase;
import com.synaptixfit.application.port.input.academic.ReviewFlashcardsUseCase;
import com.synaptixfit.application.port.input.academic.ReviewStudyMaterialUseCase;
import com.synaptixfit.domain.model.academic.StudySourceType;
import com.synaptixfit.infrastructure.adapter.input.rest.academic.dto.MaterialDtos.FlashcardReviewRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.academic.dto.MaterialDtos.FlashcardReviewResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.academic.dto.MaterialDtos.RegisterMaterialRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.academic.dto.MaterialDtos.ReviewPreviewResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.academic.dto.MaterialDtos.ReviewRecordResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.academic.dto.MaterialDtos.ReviewRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.academic.dto.MaterialDtos.ReviewResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.academic.dto.MaterialDtos.StudyMaterialResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.academic.dto.SubjectDtos.RetentionResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.support.CurrentUserId;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/** Materiales de estudio y repaso espaciado SM-2-Physio. */
@Tag(name = "Academic - Study materials")
@RestController
@RequestMapping("/api/v1")
public class StudyMaterialController {

    private final RegisterStudyMaterialUseCase register;
    private final ListStudyMaterialsUseCase list;
    private final ListDueStudyMaterialsUseCase listDue;
    private final GetStudyMaterialUseCase get;
    private final DeleteStudyMaterialUseCase delete;
    private final GetRetentionMetricsUseCase retention;
    private final PreviewReviewIntervalsUseCase preview;
    private final ReviewStudyMaterialUseCase review;
    private final ListReviewHistoryUseCase history;
    private final ReviewFlashcardsUseCase flashcards;

    public StudyMaterialController(RegisterStudyMaterialUseCase register, ListStudyMaterialsUseCase list,
                                   ListDueStudyMaterialsUseCase listDue, GetStudyMaterialUseCase get,
                                   DeleteStudyMaterialUseCase delete, GetRetentionMetricsUseCase retention,
                                   PreviewReviewIntervalsUseCase preview, ReviewStudyMaterialUseCase review,
                                   ListReviewHistoryUseCase history, ReviewFlashcardsUseCase flashcards) {
        this.register = register;
        this.list = list;
        this.listDue = listDue;
        this.get = get;
        this.delete = delete;
        this.retention = retention;
        this.preview = preview;
        this.review = review;
        this.history = history;
        this.flashcards = flashcards;
    }

    /** Idempotente: si el apunte o archivo ya es material, devuelve el existente. */
    @PostMapping("/study-materials")
    @ResponseStatus(HttpStatus.CREATED)
    public StudyMaterialResponse register(@CurrentUserId UUID userId, @Valid @RequestBody RegisterMaterialRequest r) {
        return StudyMaterialResponse.from(register.registerMaterial(userId, r.originType(), r.originId()));
    }

    @GetMapping("/study-materials")
    public List<StudyMaterialResponse> list(@CurrentUserId UUID userId,
                                            @RequestParam(required = false) UUID subjectId,
                                            @RequestParam(required = false) StudySourceType originType,
                                            @RequestParam(required = false) UUID originId) {
        return list.listMaterials(new ListStudyMaterialsUseCase.Query(userId, subjectId, originType, originId))
                .stream().map(StudyMaterialResponse::from).toList();
    }

    @GetMapping("/study-materials/due")
    public List<StudyMaterialResponse> due(@CurrentUserId UUID userId,
                                           @RequestParam(defaultValue = "20") int limit) {
        return listDue.listDue(userId, limit).stream().map(StudyMaterialResponse::from).toList();
    }

    @GetMapping("/study-materials/{materialId}")
    public StudyMaterialResponse get(@CurrentUserId UUID userId, @PathVariable UUID materialId) {
        return StudyMaterialResponse.from(get.getMaterial(userId, materialId));
    }

    @DeleteMapping("/study-materials/{materialId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@CurrentUserId UUID userId, @PathVariable UUID materialId) {
        delete.deleteMaterial(userId, materialId);
    }

    @GetMapping("/subjects/{subjectId}/retention")
    public RetentionResponse retention(@CurrentUserId UUID userId, @PathVariable UUID subjectId) {
        return RetentionResponse.from(retention.retention(userId, subjectId));
    }

    @GetMapping("/study-materials/{materialId}/review-preview")
    public ReviewPreviewResponse preview(@CurrentUserId UUID userId, @PathVariable UUID materialId) {
        return ReviewPreviewResponse.from(preview.previewReview(userId, materialId));
    }

    @PostMapping("/study-materials/{materialId}/reviews")
    public ReviewResponse review(@CurrentUserId UUID userId, @PathVariable UUID materialId,
                                 @Valid @RequestBody ReviewRequest r) {
        return ReviewResponse.from(review.review(userId, materialId, r.quality()));
    }

    @GetMapping("/study-materials/{materialId}/reviews")
    public List<ReviewRecordResponse> history(@CurrentUserId UUID userId, @PathVariable UUID materialId) {
        return history.reviewHistory(userId, materialId).stream().map(ReviewRecordResponse::from).toList();
    }

    @PostMapping("/study-materials/{materialId}/flashcard-reviews")
    public FlashcardReviewResponse flashcards(@CurrentUserId UUID userId, @PathVariable UUID materialId,
                                              @Valid @RequestBody FlashcardReviewRequest r) {
        return FlashcardReviewResponse.from(flashcards.reviewFlashcards(new ReviewFlashcardsUseCase.Command(userId,
                materialId, r.mastered(), r.doubtful(), r.failed())));
    }
}
