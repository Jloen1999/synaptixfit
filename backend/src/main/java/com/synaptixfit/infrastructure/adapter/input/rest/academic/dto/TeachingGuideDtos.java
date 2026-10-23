package com.synaptixfit.infrastructure.adapter.input.rest.academic.dto;

import com.synaptixfit.application.port.input.academic.ApplyTeachingGuideImportUseCase;
import com.synaptixfit.domain.model.academic.TeachingGuide;
import com.synaptixfit.domain.model.academic.TeachingGuide.AssessmentKind;
import com.synaptixfit.domain.model.academic.TeachingGuide.EvaluationMode;
import com.synaptixfit.domain.model.academic.TeachingGuide.TopicKind;
import com.synaptixfit.domain.model.academic.TeachingGuideImport;
import com.synaptixfit.domain.model.academic.TeachingGuideImportView;
import jakarta.validation.Valid;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/**
 * DTOs del plan docente: borrador editable de la guía (lo que la IA extrajo y el estudiante revisa)
 * e importaciones (subida, estado, aplicación).
 */
public final class TeachingGuideDtos {

    private TeachingGuideDtos() {
    }

    // ------------------------------------------------------------------ borrador de guía

    public record SubjectInfoDto(@Size(max = 150) String name, @Size(max = 50) String code,
                                 @DecimalMin("0") @DecimalMax("60") Double ectsCredits, Integer courseYear,
                                 Integer semester, @Size(max = 60) String character, @Size(max = 300) String degree,
                                 @Size(max = 200) String center, @Size(max = 200) String university,
                                 @Size(max = 20) String academicYear, @Size(max = 200) String department,
                                 @Size(max = 2000) String description) {

        public static SubjectInfoDto from(TeachingGuide.SubjectInfo s) {
            return new SubjectInfoDto(s.name(), s.code(), s.ectsCredits(), s.courseYear(), s.semester(), s.character(),
                    s.degree(), s.center(), s.university(), s.academicYear(), s.department(), s.description());
        }

        TeachingGuide.SubjectInfo toDomain() {
            return new TeachingGuide.SubjectInfo(name, code, ectsCredits, courseYear, semester, character, degree,
                    center, university, academicYear, department, description);
        }
    }

    public record ProfessorDraftDto(@Size(max = 150) String name, @Size(max = 200) String email,
                                    @Size(max = 100) String office) {
    }

    public record TopicDraftDto(@Size(max = 300) String title, TopicKind kind,
                                @Size(max = 40) List<@Size(max = 300) String> subtopics, Double hours) {
    }

    public record AssessmentDraftDto(@Size(max = 200) String name,
                                     @DecimalMin("0") @DecimalMax("100") double percentage, EvaluationMode mode,
                                     AssessmentKind kind, Integer durationMinutes,
                                     @Size(max = 100) List<Integer> topicNumbers, Boolean recoverable,
                                     LocalDate dueDate) {
    }

    public record GuideDraftDto(@Valid SubjectInfoDto subject,
                                @Size(max = 20) List<@Valid ProfessorDraftDto> professors,
                                @Size(max = 100) List<@Valid TopicDraftDto> topics,
                                @Size(max = 50) List<@Valid AssessmentDraftDto> assessments,
                                @Size(max = 100) List<@Size(max = 1000) String> bibliography,
                                EvaluationMode selectedMode) {

        public static GuideDraftDto from(TeachingGuide g) {
            return new GuideDraftDto(SubjectInfoDto.from(g.subject()),
                    g.professors().stream().map(p -> new ProfessorDraftDto(p.name(), p.email(), p.office())).toList(),
                    g.topics().stream().map(t -> new TopicDraftDto(t.title(), t.kind(), t.subtopics(), t.hours()))
                            .toList(),
                    g.assessments().stream().map(a -> new AssessmentDraftDto(a.name(), a.percentage(), a.mode(),
                            a.kind(), a.durationMinutes(), a.topicNumbers(), a.recoverable(), a.dueDate())).toList(),
                    g.bibliography(), g.selectedMode());
        }

        public TeachingGuide toDomain() {
            return new TeachingGuide(subject == null ? null : subject.toDomain(),
                    professors == null ? List.of() : professors.stream()
                            .map(p -> new TeachingGuide.Professor(p.name(), p.email(), p.office())).toList(),
                    topics == null ? List.of() : topics.stream()
                            .map(t -> new TeachingGuide.Topic(t.title(), t.kind(), false, t.subtopics(), t.hours()))
                            .toList(),
                    assessments == null ? List.of() : assessments.stream()
                            .map(a -> new TeachingGuide.Assessment(a.name(), a.percentage(), null, a.mode(), a.kind(),
                                    a.durationMinutes(), a.topicNumbers(), a.recoverable(), a.dueDate()))
                            .toList(),
                    bibliography, selectedMode);
        }
    }

    // ------------------------------------------------------------------ importaciones

    public record ImportUploadRequest(@NotBlank @Size(max = 255) String fileName,
                                      @NotBlank @Size(max = 150) String mimeType,
                                      @NotNull @Positive Long sizeBytes) {
    }

    public record StartImportRequest(@NotBlank @Size(max = 1024) String objectKey,
                                     @NotBlank @Size(max = 255) String fileName,
                                     @NotBlank @Size(max = 150) String mimeType,
                                     @NotNull @Positive Long sizeBytes, UUID targetSubjectId) {
    }

    /** {@code subjectId} nulo crea una asignatura nueva; {@code guide} nulo aplica lo extraído tal cual. */
    public record ApplyImportRequest(UUID subjectId, @Valid GuideDraftDto guide, boolean createDeadlines) {
    }

    public record ApplyImportResponse(UUID subjectId, boolean subjectCreated, int deadlinesRequested) {

        public static ApplyImportResponse from(ApplyTeachingGuideImportUseCase.Result r) {
            return new ApplyImportResponse(r.subjectId(), r.subjectCreated(), r.deadlinesRequested());
        }
    }

    /** Estado de la importación; {@code guide} solo llega cuando está lista o aplicada. */
    public record ImportResponse(UUID id, TeachingGuideImport.Status status, String errorCode, String fileName,
                                 UUID targetSubjectId, UUID suggestedSubjectId, String suggestedSubjectName,
                                 UUID appliedSubjectId, GuideDraftDto guide, Instant createdAt, Instant updatedAt) {

        public static ImportResponse from(TeachingGuideImportView v) {
            TeachingGuideImport i = v.guideImport();
            boolean withGuide = i.guide() != null && (v.status() == TeachingGuideImport.Status.READY
                    || v.status() == TeachingGuideImport.Status.APPLIED);
            return new ImportResponse(i.id(), v.status(), v.errorCode(), i.fileName(), i.targetSubjectId(),
                    v.suggestedSubjectId(), v.suggestedSubjectName(), i.appliedSubjectId(),
                    withGuide ? GuideDraftDto.from(i.guide()) : null, i.createdAt(), i.updatedAt());
        }
    }
}
