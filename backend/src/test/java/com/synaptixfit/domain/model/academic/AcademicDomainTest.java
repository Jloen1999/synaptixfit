package com.synaptixfit.domain.model.academic;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.assertj.core.api.Assertions.within;

import com.synaptixfit.domain.exception.FieldValidationException;
import com.synaptixfit.domain.exception.academic.FileTooLargeException;
import com.synaptixfit.domain.exception.academic.FileTypeNotAllowedException;
import com.synaptixfit.domain.exception.academic.QuestionNotFoundException;
import com.synaptixfit.domain.exception.academic.TestSessionNotInProgressException;
import com.synaptixfit.domain.model.neuro.FatigueAdjustedRecall;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

/** Reglas de dominio del módulo académico con casos numéricos. */
class AcademicDomainTest {

    @Nested
    class Sm2 {

        @Test
        void firstSuccessfulRepetitionsUseOneAndSixDays() {
            SpacedRepetition.Result r1 = SpacedRepetition.next(5, 0, 2.5, 0);
            assertThat(r1.intervalDays()).isEqualTo(1);
            assertThat(r1.repetitions()).isEqualTo(1);
            assertThat(r1.easeFactor()).isCloseTo(2.6, within(1e-9));
            assertThat(r1.masteryState()).isEqualTo(MasteryState.IN_PROGRESS);

            SpacedRepetition.Result r2 = SpacedRepetition.next(4, 1, 2.6, 1);
            assertThat(r2.intervalDays()).isEqualTo(6);
            assertThat(r2.easeFactor()).isCloseTo(2.6, within(1e-9));
        }

        @Test
        void laterRepetitionsMultiplyByPreviousEaseAndMaster() {
            SpacedRepetition.Result r3 = SpacedRepetition.next(3, 6, 2.6, 2);
            assertThat(r3.intervalDays()).isEqualTo(16); // ceil(6 * 2.6 = 15.6)
            assertThat(r3.repetitions()).isEqualTo(3);
            assertThat(r3.masteryState()).isEqualTo(MasteryState.MASTERED);
            assertThat(r3.easeFactor()).isCloseTo(2.46, within(1e-9)); // 2.6 + 0.1 - 2 * 0.12
        }

        @Test
        void failureResetsRepetitionsAndPenalizesEase() {
            SpacedRepetition.Result fail = SpacedRepetition.next(2, 16, 2.5, 3);
            assertThat(fail.failed()).isTrue();
            assertThat(fail.repetitions()).isZero();
            assertThat(fail.intervalDays()).isEqualTo(1);
            assertThat(fail.masteryState()).isEqualTo(MasteryState.IN_PROGRESS);
            assertThat(fail.easeFactor()).isCloseTo(2.18, within(1e-9)); // 2.5 + 0.1 - 3 * 0.14

            SpacedRepetition.Result blackout = SpacedRepetition.next(0, 1, 2.5, 0);
            assertThat(blackout.masteryState()).isEqualTo(MasteryState.NEEDS_REVIEW);
            assertThat(blackout.easeFactor()).isCloseTo(1.7, within(1e-9)); // 2.5 + 0.1 - 5 * 0.18
        }

        @Test
        void easeIsClampedAndFractionalQualityIsNotRounded() {
            assertThat(SpacedRepetition.next(0, 1, 1.4, 0).easeFactor()).isEqualTo(1.3);
            assertThat(SpacedRepetition.next(5, 1, 3.0, 0).easeFactor()).isEqualTo(3.0);

            SpacedRepetition.Result r = SpacedRepetition.next(3, 2.5, 0, 2.5, 0);
            assertThat(r.failed()).isFalse();
            assertThat(r.easeFactor()).isCloseTo(2.275, within(1e-9)); // 2.5 + 0.1 - 2.5 * 0.13

            assertThatThrownBy(() -> SpacedRepetition.next(5, 5.1, 0, 2.5, 0))
                    .isInstanceOf(FieldValidationException.class);
            assertThatThrownBy(() -> SpacedRepetition.next(6, 0, 2.5, 0))
                    .isInstanceOf(FieldValidationException.class);
        }

        @Test
        void fatigueAdjustmentFeedsSm2WithTheExactFraction() {
            double adjusted = FatigueAdjustedRecall.adjustedQuality(2, 450, 600);
            assertThat(adjusted).isCloseTo(2.375, within(1e-9));
            SpacedRepetition.Result r = SpacedRepetition.next(2, adjusted, 0, 2.5, 0);
            assertThat(r.failed()).isTrue();
            double d = 5 - 2.375;
            assertThat(r.easeFactor()).isCloseTo(2.5 + 0.1 - d * (0.08 + d * 0.02), within(1e-9));
        }

        @Test
        void materialReviewUpdatesCountersAndDates() {
            Instant now = Instant.parse("2026-10-18T10:00:00Z");
            StudyMaterial m = StudyMaterial.create(UUID.randomUUID(), UUID.randomUUID(), StudySourceType.NOTE,
                    UUID.randomUUID(), "Tema", now);
            m.review(1, 1, now);
            assertThat(m.failedReviews()).isEqualTo(1);
            assertThat(m.masteryState()).isEqualTo(MasteryState.NEEDS_REVIEW);
            assertThat(m.nextReviewAt()).isEqualTo(Instant.parse("2026-10-19T10:00:00Z"));
            assertThat(m.lastReviewedAt()).isEqualTo(now);
            // Tras repasar, el siguiente repaso queda a un día: repetirlo hoy no toca (no da XP).
            assertThat(m.isReviewOwed(now)).isFalse();
            assertThat(m.isReviewOwed(Instant.parse("2026-10-19T10:00:00Z"))).isTrue();
        }

        @Test
        void fatigueNeverTurnsAFailureIntoASuccess() {
            // Con fatiga máxima un 2 sube a 2,5: antes se redondeaba a 3 y contaba como acierto.
            SpacedRepetition.Result r = SpacedRepetition.next(2, 2.5, 16, 2.5, 3);
            assertThat(r.failed()).isTrue();
            assertThat(r.repetitions()).isZero();
            assertThat(r.intervalDays()).isEqualTo(1);
            assertThat(r.easeFactor()).isCloseTo(2.275, within(1e-9)); // la fatiga suaviza solo el EF
        }

        @Test
        void earlySuccessDoesNotAdvanceTheScheduleButEarlyFailureResets() {
            Instant now = Instant.parse("2026-10-18T10:00:00Z");
            StudyMaterial m = StudyMaterial.create(UUID.randomUUID(), UUID.randomUUID(), StudySourceType.NOTE,
                    UUID.randomUUID(), "Tema", now);
            m.review(5, 5, now);
            Instant due = m.nextReviewAt();
            for (int i = 1; i <= 3; i++) {
                m.review(5, 5, now.plusSeconds(60L * i));
            }
            assertThat(m.completedReviews()).isEqualTo(1);
            assertThat(m.masteryState()).isEqualTo(MasteryState.IN_PROGRESS);
            assertThat(m.nextReviewAt()).isEqualTo(due);
            assertThat(m.lastReviewedAt()).isEqualTo(now.plusSeconds(180));

            m.review(1, 1, now.plusSeconds(600));
            assertThat(m.completedReviews()).isZero();
            assertThat(m.failedReviews()).isEqualTo(1);
            assertThat(m.nextReviewAt()).isEqualTo(now.plusSeconds(600).plus(java.time.Duration.ofDays(1)));
        }
    }

    @Nested
    class Guides {

        @Test
        void gradeCalculatorEstimatesAndComputesRequiredGrade() {
            TeachingGuide guide = new TeachingGuide(List.of(), List.of(),
                    List.of(new TeachingGuide.Assessment("Examen", 60, 8.0),
                            new TeachingGuide.Assessment("Prácticas", 40, null)), List.of());
            TeachingGuide.GradeEstimate e = guide.estimate();
            assertThat(e.estimatedGrade()).isEqualTo(8.0);
            assertThat(e.coveredPercentage()).isEqualTo(60);
            assertThat(e.requiredGradeToPass()).isEqualTo(0.5); // (50 - 48) / 40 * 10
            assertThat(e.nextPendingAssessment()).isEqualTo("Prácticas");

            TeachingGuide graded = guide.withGrade(1, 4.0);
            assertThat(graded.estimate().estimatedGrade()).isEqualTo(6.4);
            assertThat(graded.estimate().requiredGradeToPass()).isNull();
            assertThatThrownBy(() -> guide.withGrade(1, 11.0)).isInstanceOf(FieldValidationException.class);
            assertThatThrownBy(() -> guide.withGrade(5, 1.0)).isInstanceOf(FieldValidationException.class);
        }

        @Test
        void syllabusProgressCountsCompletedTopics() {
            TeachingGuide guide = new TeachingGuide(List.of(), List.of(
                    new TeachingGuide.Topic("T1", TeachingGuide.TopicKind.THEORY, false),
                    new TeachingGuide.Topic("P1", TeachingGuide.TopicKind.PRACTICE, false)), List.of(), List.of());
            assertThat(guide.withTopicCompleted(0, true).syllabusProgress()).isEqualTo(0.5);
            assertThat(guide.hasData()).isTrue();
            assertThat(new TeachingGuide(null, null, null, null).hasData()).isFalse();
        }

        @Test
        void mindMapParsesIndentedMarkdownWithMaxDepthAndSerializes() {
            String md = """
                    - Bases de datos
                      - Modelo relacional
                        - Tablas
                          - Filas
                            - Demasiado profundo
                      - SQL
                    """;
            MindMap map = MindMap.fromIndentedMarkdown("BBDD", md);
            assertThat(map.central()).isEqualTo("BBDD");
            assertThat(map.branches()).extracting(MindMapNode::title).containsExactly("Modelo relacional", "SQL");
            MindMapNode tables = map.branches().getFirst().children().getFirst();
            assertThat(tables.children()).extracting(MindMapNode::title).containsExactly("Filas");
            assertThat(tables.children().getFirst().children()).isEmpty();
            assertThat(map.toMarkdown()).isEqualTo("# BBDD\n\n## Modelo relacional\n- Tablas\n  - Filas\n\n## SQL\n");
        }
    }

    @Nested
    class FilesAndQuizzes {

        @Test
        void uploadPolicyValidatesAndBuildsOwnedKeys() {
            UUID user = UUID.randomUUID();
            UUID subject = UUID.randomUUID();
            assertThat(FileUploadPolicy.validate("Application/PDF", 10)).isEqualTo("application/pdf");
            assertThatThrownBy(() -> FileUploadPolicy.validate("video/mp4", 10))
                    .isInstanceOf(FileTypeNotAllowedException.class);
            assertThatThrownBy(() -> FileUploadPolicy.validate("application/pdf", FileUploadPolicy.MAX_SIZE_BYTES + 1))
                    .isInstanceOf(FileTooLargeException.class);
            assertThat(FileUploadPolicy.sanitizeFileName("../mis apuntes!!.pdf")).isEqualTo(".._mis_apuntes_.pdf");
            String key = FileUploadPolicy.objectKey(user, subject, "a b.pdf", Instant.ofEpochMilli(42));
            assertThat(key).endsWith("/archivos/42_a_b.pdf");
            assertThat(FileUploadPolicy.isKeyOf(key, user, subject)).isTrue();
            assertThat(FileUploadPolicy.isKeyOf(key, UUID.randomUUID(), subject)).isFalse();
            assertThat(FileUploadPolicy.isKeyOf(FileUploadPolicy.keyPrefix(user, subject) + "../x", user, subject))
                    .isFalse();
        }

        @Test
        void questionsAreGradedTolerantly() {
            Question q = Question.from(new QuestionDraft(QuestionType.FILL_IN_BLANK, "La ___", null, "Mitocondria",
                    null), UUID.randomUUID(), 0);
            assertThat(q.isCorrect("  mitocondria. ")).isTrue();
            assertThat(q.isCorrect("MITOCÓNDRIA")).isTrue();
            assertThat(q.isCorrect("núcleo")).isFalse();
            assertThat(q.isCorrect(null)).isFalse();
            assertThatThrownBy(() -> new QuestionDraft(QuestionType.MULTIPLE_CHOICE, "¿?", List.of("A", "B"), "C",
                    null)).isInstanceOf(FieldValidationException.class);
        }

        @Test
        void testSessionStateMachineAndXpClaim() {
            UUID q1 = UUID.randomUUID();
            UUID q2 = UUID.randomUUID();
            TestSession s = TestSession.start(UUID.randomUUID(), UUID.randomUUID(), List.of(q1, q2), Instant.EPOCH);
            s.answer(q1, "a", true, null);
            assertThat(s.currentIndex()).isEqualTo(1);
            assertThatThrownBy(() -> s.answer(UUID.randomUUID(), "x", false, null))
                    .isInstanceOf(QuestionNotFoundException.class);
            assertThat(s.claimXp()).isFalse(); // aún en curso
            s.answer(q2, "b", false, null);
            s.complete(Instant.EPOCH);
            assertThat(s.score()).isEqualTo(1);
            assertThat(s.claimXp()).isTrue();
            assertThat(s.claimXp()).isFalse();
            assertThatThrownBy(() -> s.abandon(Instant.EPOCH)).isInstanceOf(TestSessionNotInProgressException.class);
        }

        @Test
        void practiceRewards() {
            assertThat(PracticeRewards.practiceXp(8, 10, 0)).isEqualTo(30);
            assertThat(PracticeRewards.practiceXp(7, 10, 4)).isEqualTo(20);
            assertThat(PracticeRewards.practiceXp(0, 0, 0)).isZero();
            // Contra el farmeo: menos de 5 preguntas o 5 tests con XP en 24 h ya no puntúan.
            assertThat(PracticeRewards.practiceXp(4, 4, 0)).isZero();
            assertThat(PracticeRewards.practiceXp(10, 10, 5)).isZero();
            assertThat(PracticeRewards.flashcardsXp(4, 3)).isEqualTo(15);
            assertThat(PracticeRewards.flashcardsQuality(5, 0, 5)).isEqualTo(4);
            assertThat(PracticeRewards.flashcardsQuality(2, 3, 5)).isEqualTo(3);
            assertThat(PracticeRewards.flashcardsQuality(1, 1, 8)).isZero();
        }
    }
}
