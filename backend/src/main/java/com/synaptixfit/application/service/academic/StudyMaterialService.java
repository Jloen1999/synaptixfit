package com.synaptixfit.application.service.academic;

import java.util.Optional;
import com.synaptixfit.domain.port.output.academic.QuestionBankRepositoryPort;
import com.synaptixfit.domain.port.output.academic.QuestionAttemptRepositoryPort;
import com.synaptixfit.domain.model.academic.Question;
import com.synaptixfit.domain.model.academic.PracticeScore;
import com.synaptixfit.application.port.input.academic.AbandonStudyMaterialUseCase;
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
import com.synaptixfit.application.port.input.gamification.AwardExperienceUseCase;
import com.synaptixfit.domain.event.academic.ReviewAbandoned;
import com.synaptixfit.domain.event.academic.ReviewCompleted;
import com.synaptixfit.domain.event.academic.ReviewScheduled;
import com.synaptixfit.domain.exception.FieldValidationException;
import com.synaptixfit.domain.model.academic.AiDocumentSource;
import com.synaptixfit.domain.model.academic.AiDocumentType;
import com.synaptixfit.domain.model.academic.FlashcardsOutcome;
import com.synaptixfit.domain.model.academic.PracticeRewards;
import com.synaptixfit.domain.model.academic.RetentionMetrics;
import com.synaptixfit.domain.model.academic.ReviewOutcome;
import com.synaptixfit.domain.model.academic.ReviewPreview;
import com.synaptixfit.domain.model.academic.ReviewRecord;
import com.synaptixfit.domain.model.academic.SpacedRepetition;
import com.synaptixfit.domain.model.academic.StudyMaterial;
import com.synaptixfit.domain.model.academic.StudySourceType;
import com.synaptixfit.domain.model.academic.Subject;
import com.synaptixfit.domain.model.neuro.FatigueAdjustedRecall;
import com.synaptixfit.domain.model.shared.Guard;
import com.synaptixfit.domain.port.output.academic.AiDocumentRepositoryPort;
import com.synaptixfit.domain.port.output.academic.NoteRepositoryPort;
import com.synaptixfit.domain.model.insights.PhysicalLoadHistory;
import com.synaptixfit.domain.port.output.academic.PhysicalLoadPort;
import com.synaptixfit.domain.port.output.academic.ReviewRecordRepositoryPort;
import com.synaptixfit.domain.port.output.academic.StudyMaterialRepositoryPort;
import com.synaptixfit.domain.port.output.academic.SubjectFileRepositoryPort;
import com.synaptixfit.domain.port.output.academic.SubjectRepositoryPort;
import com.synaptixfit.domain.port.output.event.DomainEventPublisherPort;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/**
 * Materiales de estudio y repaso espaciado SM-2-Physio: la calidad declarada se ajusta por la
 * fatiga física del día (Fórmula 4), se audita cada repaso, se concede XP si el repaso tocaba
 * ({@link PracticeRewards}) y se publican {@link ReviewCompleted} y {@link ReviewScheduled} para que
 * el planificador complete el bloque de repaso pendiente y prepare el de la siguiente fecha.
 */
public class StudyMaterialService implements RegisterStudyMaterialUseCase, ListStudyMaterialsUseCase,
        ListDueStudyMaterialsUseCase, GetStudyMaterialUseCase, DeleteStudyMaterialUseCase, AbandonStudyMaterialUseCase,
        GetRetentionMetricsUseCase,
        PreviewReviewIntervalsUseCase, ReviewStudyMaterialUseCase, ListReviewHistoryUseCase, ReviewFlashcardsUseCase {

    static final int MAX_DUE = 100;

    private final StudyMaterialRepositoryPort materials;
    private final ReviewRecordRepositoryPort reviews;
    private final PhysicalLoadPort physicalLoad;
    private final AiDocumentRepositoryPort aiDocuments;
    private final DomainEventPublisherPort events;
    private final AwardExperienceUseCase awardExperience;
    private final Clock clock;
    private final ZoneId zone;
    private final AcademicLookups lookups;
    private final QuestionBankRepositoryPort banks;
    private final QuestionAttemptRepositoryPort attempts;

    /**
     * @param zone     zona que define «hoy» para la carga física del día (la misma que usan los indicadores)
     * @param banks    bancos de preguntas, para proponer la nota del repaso con la práctica reciente
     *                 ({@link PracticeScore})
     * @param attempts respuestas a esas preguntas
     */
    public StudyMaterialService(StudyMaterialRepositoryPort materials, ReviewRecordRepositoryPort reviews,
                                PhysicalLoadPort physicalLoad, SubjectRepositoryPort subjects,
                                NoteRepositoryPort notes, SubjectFileRepositoryPort files,
                                AiDocumentRepositoryPort aiDocuments, DomainEventPublisherPort events,
                                AwardExperienceUseCase awardExperience, Clock clock, ZoneId zone,
                                QuestionBankRepositoryPort banks, QuestionAttemptRepositoryPort attempts) {
        this.banks = banks;
        this.attempts = attempts;
        this.materials = materials;
        this.reviews = reviews;
        this.physicalLoad = physicalLoad;
        this.aiDocuments = aiDocuments;
        this.events = events;
        this.awardExperience = awardExperience;
        this.clock = clock;
        this.zone = zone;
        this.lookups = new AcademicLookups(subjects, notes, files, materials, null, clock);
    }

    @Override
    public StudyMaterial registerMaterial(UUID userId, StudySourceType originType, UUID originId) {
        Guard.notNull(originType, "originType");
        Guard.notNull(originId, "originId");
        return lookups.ensureMaterial(userId, originType, originId);
    }

    @Override
    public List<StudyMaterial> listMaterials(ListStudyMaterialsUseCase.Query q) {
        if (q.subjectId() != null) {
            lookups.subject(q.userId(), q.subjectId());
        }
        if (q.originType() != null && q.originId() != null) {
            return materials.findByOrigin(q.userId(), q.originType(), q.originId())
                    .filter(m -> q.subjectId() == null || m.subjectId().equals(q.subjectId()))
                    .map(List::of).orElse(List.of());
        }
        return materials.findByUser(q.userId(), q.subjectId()).stream()
                .filter(m -> q.originType() == null || m.originType() == q.originType())
                .toList();
    }

    @Override
    public List<StudyMaterial> listDue(UUID userId, int limit) {
        return materials.findDue(userId, clock.instant(), Math.max(1, Math.min(limit, MAX_DUE)));
    }

    @Override
    public StudyMaterial getMaterial(UUID userId, UUID materialId) {
        return lookups.material(userId, materialId);
    }

    @Override
    public void deleteMaterial(UUID userId, UUID materialId) {
        StudyMaterial m = lookups.material(userId, materialId);
        // El banco de práctica cae en cascada: la marca de práctica de la fuente deja de tener sentido.
        aiDocuments.find(userId, AiDocumentSource.of(m.originType()), m.originId().toString(), AiDocumentType.PRACTICE)
                .ifPresent(d -> aiDocuments.delete(d.id()));
        materials.delete(m.id());
    }

    @Override
    public StudyMaterial abandonMaterial(UUID userId, UUID materialId) {
        StudyMaterial m = lookups.material(userId, materialId);
        m.abandon();
        StudyMaterial saved = materials.save(m);
        events.publish(new ReviewAbandoned(userId, saved.id(), clock.instant()));
        return saved;
    }

    @Override
    public RetentionMetrics retention(UUID userId, UUID subjectId) {
        Subject s = lookups.subject(userId, subjectId);
        return RetentionMetrics.of(materials.findByUser(userId, s.id()));
    }

    @Override
    public ReviewPreview previewReview(UUID userId, UUID materialId) {
        StudyMaterial m = lookups.material(userId, materialId);
        Instant now = clock.instant();
        Fatigue f = fatigue(userId, now);
        List<ReviewPreview.Option> options = new ArrayList<>();
        for (int q = 0; q <= 5; q++) {
            double adjusted = FatigueAdjustedRecall.adjustedQuality(q, f.today(), f.max());
            SpacedRepetition.Result r = m.simulate(q, adjusted, now);
            options.add(new ReviewPreview.Option(q, round(adjusted, 2), r.intervalDays(),
                    m.nextReviewAfter(r, now), r.masteryState()));
        }
        return new ReviewPreview(f.today(), f.max(), round(f.coefficient(), 3), options,
                recentPractice(userId, m, now).orElse(null));
    }

    /** Práctica con preguntas del material en las últimas horas, para proponer la nota del repaso. */
    private Optional<PracticeScore> recentPractice(UUID userId, StudyMaterial m, Instant now) {
        List<UUID> questionIds = banks.findByMaterial(m.id())
                .map(b -> banks.findQuestions(b.id()).stream().map(Question::id).toList())
                .orElse(List.of());
        if (questionIds.isEmpty()) {
            return Optional.empty();
        }
        return PracticeScore.from(attempts.findByUserAndQuestions(userId, questionIds), m.lastReviewedAt(), now);
    }

    @Override
    public ReviewOutcome review(UUID userId, UUID materialId, int quality) {
        Guard.range(quality, "quality", 0, 5);
        StudyMaterial m = lookups.material(userId, materialId);
        return applyReview(userId, m, quality, PracticeRewards.reviewXp(m.isReviewOwed(clock.instant())));
    }

    @Override
    public List<ReviewRecord> reviewHistory(UUID userId, UUID materialId) {
        StudyMaterial m = lookups.material(userId, materialId);
        return reviews.findByMaterial(m.id());
    }

    @Override
    public FlashcardsOutcome reviewFlashcards(ReviewFlashcardsUseCase.Command c) {
        Guard.range(c.mastered(), "mastered", 0, 500);
        Guard.range(c.doubtful(), "doubtful", 0, 500);
        Guard.range(c.failed(), "failed", 0, 500);
        if (c.mastered() + c.doubtful() + c.failed() == 0) {
            throw new FieldValidationException("mastered", "REQUIRED",
                    "at least one flashcard result is required");
        }
        StudyMaterial m = lookups.material(c.userId(), c.materialId());
        int quality = PracticeRewards.flashcardsQuality(c.mastered(), c.doubtful(), c.failed());
        int xp = PracticeRewards.flashcardsReviewXp(m.isReviewOwed(clock.instant()), c.mastered(), c.doubtful());
        ReviewOutcome outcome = applyReview(c.userId(), m, quality, xp);
        return new FlashcardsOutcome(outcome.material(), outcome.record(), quality, outcome.xpAwarded());
    }

    /**
     * Aplica el repaso, concede {@code xp} (ya decidida según si tocaba) y publica primero
     * {@link ReviewCompleted} (completa el bloque de repaso pendiente) y después {@link ReviewScheduled}
     * (mueve o crea el bloque de la siguiente fecha).
     */
    private ReviewOutcome applyReview(UUID userId, StudyMaterial m, int quality, int xp) {
        Instant now = clock.instant();
        Fatigue f = fatigue(userId, now);
        double adjusted = FatigueAdjustedRecall.adjustedQuality(quality, f.today(), f.max());
        m.review(quality, adjusted, now);
        if (xp > 0) {
            m.markPracticeXpAwarded();
        }
        StudyMaterial saved = materials.save(m);
        ReviewRecord record = reviews.save(new ReviewRecord(UUID.randomUUID(), saved.id(), now, quality,
                round(adjusted, 2), round(f.coefficient(), 3)));
        if (xp > 0) {
            awardExperience.award(userId, xp);
        }
        events.publish(new ReviewCompleted(userId, saved.id(), saved.subjectId(), quality, xp, now));
        events.publish(new ReviewScheduled(userId, saved.id(), saved.subjectId(), "Repaso: " + saved.title(),
                saved.nextReviewAt(), now));
        return new ReviewOutcome(saved, record, xp);
    }

    /** Carga de hoy y máxima diaria histórica (la de hoy cuenta para el máximo). */
    private Fatigue fatigue(UUID userId, Instant now) {
        List<PhysicalLoadHistory.Entry> history = physicalLoad.history(userId);
        LocalDate day = LocalDate.ofInstant(now, zone);
        double today = PhysicalLoadHistory.total(history, day, day);
        double max = Math.max(PhysicalLoadHistory.maxDailyLoad(history), today);
        return new Fatigue(today, max, FatigueAdjustedRecall.fatigueCoefficient(today, max));
    }

    private static double round(double value, int decimals) {
        double factor = Math.pow(10, decimals);
        return Math.round(value * factor) / factor;
    }

    private record Fatigue(double today, double max, double coefficient) {
    }
}
