package com.synaptixfit.infrastructure.adapter.input.rest.academic.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import com.synaptixfit.domain.model.academic.CatalogSubjectSelection;
import com.synaptixfit.domain.model.academic.RetentionMetrics;
import com.synaptixfit.domain.model.academic.Subject;
import com.synaptixfit.domain.model.academic.SubjectPriority;
import com.synaptixfit.domain.model.academic.SubjectSemester;
import com.synaptixfit.domain.model.academic.SubjectSummary;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

/** DTOs de asignaturas, catálogo, semestres y retención. */
public final class SubjectDtos {

    private SubjectDtos() {
    }

    /** Alta de asignatura; los campos opcionales nulos toman su valor por defecto. */
    public record CreateSubjectRequest(@NotBlank @Size(min = 2, max = 150) String name,
                                       @Size(max = 50) String code,
                                       @Size(max = 2000) String description,
                                       @Min(1) @Max(30) Integer credits,
                                       @Min(1) @Max(5) Integer perceivedDifficulty,
                                       SubjectPriority priority,
                                       Instant nextAssessmentAt,
                                       @Size(max = 150) String teacher,
                                       @Size(max = 2048) String icsUrl) {
    }

    /** Edición parcial: nulos sin cambios, texto en blanco borra el valor opcional. */
    public record UpdateSubjectRequest(@Size(min = 2, max = 150) String name,
                                       @Size(max = 50) String code,
                                       @Size(max = 2000) String description,
                                       @Min(1) @Max(30) Integer credits,
                                       @Min(1) @Max(5) Integer perceivedDifficulty,
                                       SubjectPriority priority,
                                       Instant nextAssessmentAt,
                                       Boolean clearNextAssessment,
                                       @Size(max = 150) String teacher,
                                       @Size(max = 2048) String icsUrl,
                                       Boolean archived) {
    }

    public record SubjectResponse(UUID id, String name, String code, String description, int credits,
                                  int perceivedDifficulty, SubjectPriority priority, Instant nextAssessmentAt,
                                  String teacher, boolean archived, UUID catalogSubjectId, String icsUrl,
                                  Instant lastSyncedAt, Instant createdAt, long noteCount, long fileCount) {

        public static SubjectResponse from(SubjectSummary s) {
            return from(s.subject(), s.noteCount(), s.fileCount());
        }

        public static SubjectResponse from(Subject s) {
            return from(s, 0, 0);
        }

        private static SubjectResponse from(Subject s, long notes, long files) {
            return new SubjectResponse(s.id(), s.name(), s.code(), s.description(), s.credits(),
                    s.perceivedDifficulty(), s.priority(), s.nextAssessmentAt(), s.teacher(), s.archived(),
                    s.catalogSubjectId(), s.icsUrl(), s.lastSyncedAt(), s.createdAt(), notes, files);
        }
    }

    @Schema(name = "AcademicCatalogSubjectResponse")

    public record CatalogSubjectResponse(UUID catalogSubjectId, UUID degreeId, String name, Integer course,
                                         Integer semester, String character, Double credits, Integer hours,
                                         String guideUrl, UUID subjectId, boolean selected) {

        public static CatalogSubjectResponse from(CatalogSubjectSelection s) {
            var c = s.catalogSubject();
            return new CatalogSubjectResponse(c.id(), c.degreeId(), c.name(), c.course(), c.semester(),
                    c.character(), c.credits(), c.hours(), c.guideUrl(), s.subjectId(), s.selected());
        }
    }

    public record CreateFromCatalogRequest(@NotEmpty @Size(max = 50) List<@NotNull UUID> catalogSubjectIds) {
    }

    public record SubjectSemesterRequest(@NotNull @Min(1) @Max(10) Integer course,
                                         @NotNull @Min(1) @Max(2) Integer semester) {
    }

    public record SubjectSemesterResponse(UUID id, UUID subjectId, int course, int semester, Instant createdAt) {

        public static SubjectSemesterResponse from(SubjectSemester s) {
            return new SubjectSemesterResponse(s.id(), s.subjectId(), s.course(), s.semester(), s.createdAt());
        }
    }

    public record RetentionResponse(int mastered, int inProgress, int needsReview, int notEvaluated, int abandoned,
                                    int total) {

        public static RetentionResponse from(RetentionMetrics m) {
            return new RetentionResponse(m.mastered(), m.inProgress(), m.needsReview(), m.notEvaluated(),
                    m.abandoned(), m.total());
        }
    }
}
