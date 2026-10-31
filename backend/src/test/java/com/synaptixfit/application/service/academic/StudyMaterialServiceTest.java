package com.synaptixfit.application.service.academic;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.assertj.core.api.Assertions.within;

import com.synaptixfit.application.port.input.academic.ReviewFlashcardsUseCase;
import com.synaptixfit.domain.event.academic.ReviewAbandoned;
import com.synaptixfit.domain.event.academic.ReviewCompleted;
import com.synaptixfit.domain.model.academic.PracticeRewards;
import com.synaptixfit.domain.event.academic.ReviewScheduled;
import com.synaptixfit.domain.exception.FieldValidationException;
import com.synaptixfit.domain.exception.academic.StudyMaterialNotFoundException;
import com.synaptixfit.domain.exception.academic.StudySourceWithoutSubjectException;
import com.synaptixfit.domain.model.academic.FlashcardsOutcome;
import com.synaptixfit.domain.model.academic.MasteryState;
import com.synaptixfit.domain.model.academic.Note;
import com.synaptixfit.domain.model.academic.ReviewOutcome;
import com.synaptixfit.domain.model.academic.ReviewPreview;
import com.synaptixfit.domain.model.academic.StudyMaterial;
import com.synaptixfit.domain.model.academic.StudySourceType;
import com.synaptixfit.domain.model.academic.Subject;
import com.synaptixfit.domain.model.insights.PhysicalLoadHistory;
import java.time.Duration;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class StudyMaterialServiceTest {

    private final AcademicFakes f = new AcademicFakes();
    private final StudyMaterialService service = new StudyMaterialService(f.materials, f.reviews, f.physicalLoad,
            f.subjects, f.notes, f.files, f.aiDocuments, f.events::add, f.award, AcademicFakes.CLOCK, ZoneOffset.UTC);
    private final UUID user = UUID.randomUUID();
    private final UUID stranger = UUID.randomUUID();

    @Test
    void registerIsIdempotentAndRequiresSubject() {
        Subject s = f.subject(user, "Física");
        Note n = f.note(user, s.id(), "Cinemática");
        StudyMaterial first = service.registerMaterial(user, StudySourceType.NOTE, n.id());
        StudyMaterial second = service.registerMaterial(user, StudySourceType.NOTE, n.id());
        assertThat(second.id()).isEqualTo(first.id());
        assertThat(first.title()).isEqualTo("Cinemática");
        assertThat(first.subjectId()).isEqualTo(s.id());

        Note loose = f.note(user, null, "Suelto");
        assertThatThrownBy(() -> service.registerMaterial(user, StudySourceType.NOTE, loose.id()))
                .isInstanceOf(StudySourceWithoutSubjectException.class);
        assertThatThrownBy(() -> service.registerMaterial(stranger, StudySourceType.NOTE, n.id()))
                .hasFieldOrPropertyWithValue("code", "NOTE_NOT_FOUND");
    }

    @Test
    void reviewWithoutFatigueAppliesSm2AuditsAndPublishesEvent() {
        Subject s = f.subject(user, "Física");
        StudyMaterial m = f.material(user, s.id(), f.note(user, s.id(), "Óptica").id());

        ReviewOutcome outcome = service.review(user, m.id(), 5);

        assertThat(outcome.material().intervalDays()).isEqualTo(1);
        assertThat(outcome.material().easeFactor()).isCloseTo(2.6, within(1e-9));
        assertThat(outcome.material().nextReviewAt()).isEqualTo(AcademicFakes.NOW.plus(Duration.ofDays(1)));
        assertThat(outcome.record().realQuality()).isEqualTo(5);
        assertThat(outcome.record().adjustedQuality()).isEqualTo(5.0);
        assertThat(outcome.record().fatigueCoefficient()).isZero();
        assertThat(f.reviewStore).hasSize(1);
        // Primer repaso de un material nuevo: tocaba, así que da la XP de repaso.
        assertThat(outcome.xpAwarded()).isEqualTo(PracticeRewards.DUE_REVIEW_XP);
        assertThat(f.events).hasSize(2);
        assertThat(f.events.get(0)).isInstanceOfSatisfying(ReviewCompleted.class, e -> {
            assertThat(e.studyMaterialId()).isEqualTo(m.id());
            assertThat(e.quality()).isEqualTo(5);
            assertThat(e.xpAwarded()).isEqualTo(PracticeRewards.DUE_REVIEW_XP);
        });
        assertThat(f.events.get(1)).isInstanceOfSatisfying(ReviewScheduled.class, e -> {
            assertThat(e.studyMaterialId()).isEqualTo(m.id());
            assertThat(e.subjectId()).isEqualTo(s.id());
            assertThat(e.dueAt()).isEqualTo(AcademicFakes.NOW.plus(Duration.ofDays(1)));
            assertThat(e.title()).isEqualTo("Repaso: Material");
        });
    }

    @Test
    void fatigueRaisesQualityWithoutRounding() {
        Subject s = f.subject(user, "Física");
        StudyMaterial m = f.material(user, s.id(), UUID.randomUUID());
        LocalDate today = LocalDate.ofInstant(AcademicFakes.NOW, ZoneOffset.UTC);
        // Hoy: dos sesiones (5 × 40 + 5 × 20 = 300 UA); el máximo diario es otro día (10 × 60 = 600).
        f.loadHistory.add(new PhysicalLoadHistory.Entry(today, 5, 40));
        f.loadHistory.add(new PhysicalLoadHistory.Entry(today, 5, 20));
        f.loadHistory.add(new PhysicalLoadHistory.Entry(today.minusDays(3), 10, 60));

        // Q_real 2 → Q_adj 2.25: es fallo (decide la calidad real) pero el EF usa 2.25.
        ReviewOutcome outcome = service.review(user, m.id(), 2);

        assertThat(outcome.record().adjustedQuality()).isEqualTo(2.25);
        assertThat(outcome.record().fatigueCoefficient()).isEqualTo(0.25);
        assertThat(outcome.material().masteryState()).isEqualTo(MasteryState.IN_PROGRESS);
        assertThat(outcome.material().failedReviews()).isEqualTo(1);
        double d = 5 - 2.25;
        assertThat(outcome.material().easeFactor()).isCloseTo(2.5 + 0.1 - d * (0.08 + d * 0.02), within(1e-9));
    }

    @Test
    void previewListsSixOptionsAndTodayCountsTowardsMax() {
        Subject s = f.subject(user, "Física");
        StudyMaterial m = f.material(user, s.id(), UUID.randomUUID());
        LocalDate today = LocalDate.ofInstant(AcademicFakes.NOW, ZoneOffset.UTC);
        f.loadHistory.add(new PhysicalLoadHistory.Entry(today, 8, 50));
        f.loadHistory.add(new PhysicalLoadHistory.Entry(today.minusDays(1), 5, 40));

        ReviewPreview preview = service.previewReview(user, m.id());

        assertThat(preview.maxDailyLoad()).isEqualTo(400);
        assertThat(preview.fatigueCoefficient()).isEqualTo(0.5);
        assertThat(preview.options()).hasSize(6);
        // Con fatiga máxima un 2 declarado sube a 2,5, pero sigue siendo un fallo (solo suaviza el EF).
        assertThat(preview.options().get(2).adjustedQuality()).isEqualTo(2.5);
        assertThat(preview.options().get(2).intervalDays()).isEqualTo(1);
        assertThat(preview.options().get(0).resultingState()).isEqualTo(MasteryState.NEEDS_REVIEW);
        assertThat(f.reviewStore).isEmpty();
        assertThat(f.events).isEmpty();
    }

    @Test
    void abandoningKeepsTheHistoryAndAsksThePlannerToDropPendingReviews() {
        Subject s = f.subject(user, "Física");
        StudyMaterial m = f.material(user, s.id(), UUID.randomUUID());
        service.review(user, m.id(), 4);
        f.events.clear();

        StudyMaterial abandoned = service.abandonMaterial(user, m.id());

        assertThat(abandoned.masteryState()).isEqualTo(MasteryState.ABANDONED);
        assertThat(abandoned.nextReviewAt()).isNull();
        assertThat(f.reviewStore).hasSize(1); // el historial se conserva
        assertThat(f.events).singleElement().isInstanceOfSatisfying(ReviewAbandoned.class,
                e -> assertThat(e.studyMaterialId()).isEqualTo(m.id()));
        assertThatThrownBy(() -> service.abandonMaterial(stranger, m.id()))
                .isInstanceOf(StudyMaterialNotFoundException.class);
    }

    @Test
    void reviewOfForeignMaterialIsNotFoundAndQualityIsValidated() {
        Subject s = f.subject(user, "Física");
        StudyMaterial m = f.material(user, s.id(), UUID.randomUUID());
        assertThatThrownBy(() -> service.review(stranger, m.id(), 3)).isInstanceOf(StudyMaterialNotFoundException.class);
        assertThatThrownBy(() -> service.review(user, m.id(), 6)).isInstanceOf(FieldValidationException.class);
    }

    @Test
    void flashcardsFeedSm2AndAwardXpOnlyWhenTheReviewIsDue() {
        Subject s = f.subject(user, "Física");
        StudyMaterial m = f.material(user, s.id(), UUID.randomUUID());

        FlashcardsOutcome first = service.reviewFlashcards(new ReviewFlashcardsUseCase.Command(user, m.id(), 6, 2, 2));
        assertThat(first.quality()).isEqualTo(4);
        assertThat(first.xpAwarded()).isEqualTo(6 * 3 + 2);
        assertThat(f.xp.get(user)).isEqualTo(20);
        assertThat(first.material().practiceXpAwarded()).isTrue();

        FlashcardsOutcome second = service.reviewFlashcards(new ReviewFlashcardsUseCase.Command(user, m.id(), 1, 1, 8));
        assertThat(second.quality()).isZero();
        assertThat(second.xpAwarded()).isZero();
        assertThat(second.material().masteryState()).isEqualTo(MasteryState.NEEDS_REVIEW);
        assertThat(f.xp.get(user)).isEqualTo(20);
        // Cada repaso publica ReviewCompleted y ReviewScheduled.
        assertThat(f.events).hasSize(4);
    }

    @Test
    void dueReviewsGiveXpOncePerDueDateNotOncePerMaterial() {
        Subject s = f.subject(user, "Física");
        StudyMaterial m = f.material(user, s.id(), UUID.randomUUID());

        assertThat(service.review(user, m.id(), 4).xpAwarded()).isEqualTo(PracticeRewards.DUE_REVIEW_XP);
        assertThat(service.review(user, m.id(), 4).xpAwarded()).isZero();

        // El repaso anticipado también avanza SM-2 (intervalo de 6 días): a la semana vuelve a tocar.
        var nextWeek = new StudyMaterialService(f.materials, f.reviews, f.physicalLoad, f.subjects, f.notes, f.files,
                f.aiDocuments, f.events::add, f.award,
                java.time.Clock.fixed(AcademicFakes.NOW.plus(Duration.ofDays(7)), ZoneOffset.UTC), ZoneOffset.UTC);
        assertThat(nextWeek.review(user, m.id(), 4).xpAwarded()).isEqualTo(PracticeRewards.DUE_REVIEW_XP);
        assertThat(f.xp.get(user)).isEqualTo(2 * PracticeRewards.DUE_REVIEW_XP);
    }

    @Test
    void flashcardsXpIsCappedPerRound() {
        Subject s = f.subject(user, "Física");
        StudyMaterial m = f.material(user, s.id(), UUID.randomUUID());

        FlashcardsOutcome big = service.reviewFlashcards(new ReviewFlashcardsUseCase.Command(user, m.id(), 100, 0, 0));

        assertThat(big.xpAwarded()).isEqualTo(PracticeRewards.FLASHCARDS_MAX_XP);
    }

    @Test
    void dueListAndRetentionMetrics() {
        Subject s = f.subject(user, "Física");
        StudyMaterial due = f.material(user, s.id(), UUID.randomUUID());
        service.review(user, due.id(), 0);
        StudyMaterial fresh = f.material(user, s.id(), UUID.randomUUID());

        assertThat(service.listDue(user, 10)).isEmpty();
        var later = new StudyMaterialService(f.materials, f.reviews, f.physicalLoad, f.subjects, f.notes, f.files,
                f.aiDocuments, f.events::add, f.award,
                java.time.Clock.fixed(AcademicFakes.NOW.plus(Duration.ofDays(2)), java.time.ZoneOffset.UTC),
                ZoneOffset.UTC);
        assertThat(later.listDue(user, 10)).extracting(StudyMaterial::id).containsExactly(due.id());

        var metrics = service.retention(user, s.id());
        assertThat(metrics.total()).isEqualTo(2);
        assertThat(metrics.needsReview()).isEqualTo(1);
        assertThat(metrics.notEvaluated()).isEqualTo(1);
        assertThat(fresh.masteryState()).isEqualTo(MasteryState.NOT_EVALUATED);
    }
}
