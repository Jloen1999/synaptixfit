package com.synaptixfit.domain.model.academic;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.domain.exception.academic.TeachingGuideImportAlreadyAppliedException;
import com.synaptixfit.domain.exception.academic.TeachingGuideImportNotReadyException;
import com.synaptixfit.domain.model.academic.TeachingGuide.AssessmentKind;
import com.synaptixfit.domain.model.academic.TeachingGuide.EvaluationMode;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class TeachingGuideTest {

    /** Plan docente real (Diseño y evaluación de tecnologías hardware, UEx): continua 30+30+20+20, global 50+50. */
    private static TeachingGuide hardwareGuide() {
        return new TeachingGuide(
                new TeachingGuide.SubjectInfo("Diseño y evaluación de tecnologías Hardware", "502376", 6.0, null, 6,
                        "Obligatoria", "Grado en Informática en Tecnologías de la Información",
                        "Centro Universitario de Mérida", "Universidad de Extremadura", "2025/2026", null, null),
                List.of(),
                List.of(new TeachingGuide.Topic("Tema 1", TeachingGuide.TopicKind.THEORY, false,
                                List.of("Prestaciones de procesadores"), 27.0),
                        new TeachingGuide.Topic("Tema 2", TeachingGuide.TopicKind.THEORY, false)),
                List.of(assessment("Prueba 1", 30, EvaluationMode.CONTINUOUS),
                        assessment("Prueba 2", 30, EvaluationMode.CONTINUOUS),
                        assessment("Trabajos parte 1", 20, EvaluationMode.CONTINUOUS),
                        assessment("Trabajos parte 2", 20, EvaluationMode.CONTINUOUS),
                        assessment("Global parte 1", 50, EvaluationMode.GLOBAL),
                        assessment("Global parte 2", 50, EvaluationMode.GLOBAL)),
                List.of(), null);
    }

    private static TeachingGuide.Assessment assessment(String name, double pct, EvaluationMode mode) {
        return new TeachingGuide.Assessment(name, pct, null, mode, AssessmentKind.EXAM, 120, List.of(1, 2, 3),
                null, null);
    }

    @Test
    void gradeEstimateOnlyCountsTheActiveEvaluationMode() {
        TeachingGuide g = hardwareGuide().withGrade(0, 8.0);

        assertThat(g.availableModes()).containsExactly(EvaluationMode.CONTINUOUS, EvaluationMode.GLOBAL);
        assertThat(g.effectiveMode()).isEqualTo(EvaluationMode.CONTINUOUS);
        assertThat(g.estimate().coveredPercentage()).isEqualTo(30);
        assertThat(g.estimate().nextPendingAssessment()).isEqualTo("Prueba 2");

        TeachingGuide global = g.withSelectedMode(EvaluationMode.GLOBAL).withGrade(4, 6.0);
        assertThat(global.estimate().coveredPercentage()).isEqualTo(50);
        assertThat(global.estimate().requiredGradeToPass()).isEqualTo(4.0);
        assertThat(global.isActive(global.assessments().get(0))).isFalse();
    }

    @Test
    void yourGradeSaysPointsAndWhichSentenceApplies() {
        TeachingGuide none = hardwareGuide();
        assertThat(none.estimate().outlook()).isEqualTo(TeachingGuide.PassOutlook.NO_GRADES);
        assertThat(none.estimate().possiblePoints()).isZero();

        // 8 en el 30 % → 2,4 de 3 puntos; faltan 2,6 puntos en el 70 % que queda: un 3,71 de media.
        TeachingGuide some = hardwareGuide().withGrade(0, 8.0);
        assertThat(some.estimate().earnedPoints()).isEqualTo(2.4);
        assertThat(some.estimate().possiblePoints()).isEqualTo(3.0);
        assertThat(some.estimate().outlook()).isEqualTo(TeachingGuide.PassOutlook.NEEDS_AVERAGE);
        assertThat(some.estimate().requiredGradeToPass()).isEqualTo(3.71);

        TeachingGuide passed = hardwareGuide().withGrade(0, 10.0).withGrade(1, 7.0);
        assertThat(passed.estimate().earnedPoints()).isEqualTo(5.1);
        assertThat(passed.estimate().outlook()).isEqualTo(TeachingGuide.PassOutlook.ALREADY_PASSED);

        // 1 y 0 en el 60 %: faltan 4,7 puntos en el 40 % que queda (haría falta un 11,75).
        TeachingGuide lost = hardwareGuide().withGrade(0, 1.0).withGrade(1, 0.0);
        assertThat(lost.estimate().outlook()).isEqualTo(TeachingGuide.PassOutlook.OUT_OF_REACH);

        TeachingGuide allFailed = hardwareGuide().withGrade(0, 4.0).withGrade(1, 4.0).withGrade(2, 4.0)
                .withGrade(3, 4.0);
        assertThat(allFailed.estimate().outlook()).isEqualTo(TeachingGuide.PassOutlook.OUT_OF_REACH);
    }

    @Test
    void professorKeepsRoleAndOfficeHoursTrimmed() {
        TeachingGuide g = new TeachingGuide(List.of(new TeachingGuide.Professor("Ana Ruiz", null, "2.15",
                "  Coordinadora ·  Teoría ", " ")), List.of(), List.of(), List.of());
        assertThat(g.professors()).singleElement().satisfies(p -> {
            assertThat(p.role()).isEqualTo("Coordinadora · Teoría");
            assertThat(p.officeHours()).isNull();
            assertThat(p.email()).isNull();
        });
    }

    @Test
    void draftFromAnOldAppKeepsRoleAndOfficeHoursOfTheExtractedGuide() {
        TeachingGuide extracted = new TeachingGuide(List.of(new TeachingGuide.Professor("Ana Ruiz", "a@u.es", "2.15",
                "Coordinadora", "Lun 10:00")), List.of(), List.of(), List.of());
        TeachingGuide oldAppDraft = new TeachingGuide(List.of(new TeachingGuide.Professor("Ana Ruiz", "a@u.es",
                "2.16"), new TeachingGuide.Professor("Luis", null, null)), List.of(), List.of(), List.of());

        TeachingGuide merged = oldAppDraft.keepingProfessorDetailsOf(extracted);

        assertThat(merged.professors().get(0).role()).isEqualTo("Coordinadora");
        assertThat(merged.professors().get(0).officeHours()).isEqualTo("Lun 10:00");
        assertThat(merged.professors().get(0).office()).isEqualTo("2.16");
        assertThat(merged.professors().get(1).role()).isNull();
    }

    @Test
    void reimportKeepsCompletedTopicsGradesAndChosenMode() {
        TeachingGuide previous = hardwareGuide().withTopicCompleted(0, true).withGrade(1, 7.0)
                .withSelectedMode(EvaluationMode.GLOBAL);

        TeachingGuide merged = hardwareGuide().keepingProgressOf(previous);

        assertThat(merged.topics().get(0).completed()).isTrue();
        assertThat(merged.topics().get(0).subtopics()).containsExactly("Prestaciones de procesadores");
        assertThat(merged.assessments().get(1).grade()).isEqualTo(7.0);
        assertThat(merged.selectedMode()).isEqualTo(EvaluationMode.GLOBAL);
    }

    @Test
    void subjectInfoNormalizesAndMatchesUserSubjects() {
        TeachingGuide.SubjectInfo info = hardwareGuide().subject();

        assertThat(info.matches("diseno y evaluacion de tecnologias  hardware", null)).isTrue();
        assertThat(info.matches("Otra", "502376")).isTrue();
        assertThat(info.matches("Otra", "999")).isFalse();
        assertThat(new TeachingGuide.SubjectInfo(null, null, 4.5, 9, 0, " ", null, null, null, null, null, null))
                .satisfies(i -> {
                    assertThat(i.roundedCredits()).isEqualTo(5);
                    assertThat(i.courseYear()).isNull();
                    assertThat(i.semester()).isNull();
                    assertThat(i.character()).isNull();
                });
    }

    @Test
    void importLifecycleTreatsStuckAnalysisAsFailedAndCanBeRetried() {
        Instant t0 = Instant.parse("2026-10-23T10:00:00Z");
        TeachingGuideImport i = TeachingGuideImport.start(UUID.randomUUID(), null, "usuarios/u/planes-docentes/1_a.pdf",
                "a.pdf", "application/pdf", 10, t0).processing(t0);

        assertThat(i.effectiveStatus(t0.plusSeconds(60))).isEqualTo(TeachingGuideImport.Status.PROCESSING);
        Instant late = t0.plus(TeachingGuideImport.STALE_PROCESSING).plusSeconds(1);
        assertThat(i.effectiveStatus(late)).isEqualTo(TeachingGuideImport.Status.FAILED);
        assertThat(i.effectiveErrorCode(late)).isEqualTo("AI_UNAVAILABLE");
        assertThatThrownBy(() -> i.requireReady(t0)).isInstanceOf(TeachingGuideImportNotReadyException.class);

        TeachingGuideImport ready = i.retried(late).processing(late).ready(hardwareGuide(), late);
        TeachingGuideImport applied = ready.applied(ready.guide(), late).appliedTo(UUID.randomUUID(), ready.guide(),
                late);
        assertThatThrownBy(() -> applied.requireReady(late))
                .isInstanceOf(TeachingGuideImportAlreadyAppliedException.class);
        assertThatThrownBy(() -> ready.retried(late)).isInstanceOf(TeachingGuideImportNotReadyException.class);
    }

    @Test
    void draftIsClippedToApiLimitsAndUnnamedAssessmentsGetAName() {
        List<TeachingGuide.Topic> many = java.util.stream.IntStream.range(0, 150)
                .mapToObj(i -> new TeachingGuide.Topic("Tema " + i, TeachingGuide.TopicKind.THEORY, false)).toList();
        TeachingGuide g = new TeachingGuide(null, null, many,
                List.of(new TeachingGuide.Assessment("", 50, null), new TeachingGuide.Assessment(" ", 50, null)),
                List.of("x".repeat(2000), " "), null);

        assertThat(g.topics()).hasSize(TeachingGuide.MAX_TOPICS);
        assertThat(g.assessments()).extracting(TeachingGuide.Assessment::name).containsExactly("Prueba 1", "Prueba 2");
        assertThat(g.bibliography()).singleElement().satisfies(b -> assertThat(b).hasSize(TeachingGuide.MAX_REFERENCE));
    }

    @Test
    void queuedImportGetsMoreTimeBeforeCountingAsFailed() {
        Instant t0 = Instant.parse("2026-10-23T10:00:00Z");
        TeachingGuideImport queued = TeachingGuideImport.start(UUID.randomUUID(), null,
                "usuarios/u/planes-docentes/1_a.pdf", "a.pdf", "application/pdf", 10, t0);

        assertThat(queued.effectiveStatus(t0.plus(TeachingGuideImport.STALE_PROCESSING).plusSeconds(1)))
                .isEqualTo(TeachingGuideImport.Status.PENDING);
        assertThat(queued.effectiveStatus(t0.plus(TeachingGuideImport.STALE_PENDING).plusSeconds(1)))
                .isEqualTo(TeachingGuideImport.Status.FAILED);
    }
}
