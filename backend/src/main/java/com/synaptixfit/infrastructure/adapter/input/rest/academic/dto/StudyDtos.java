package com.synaptixfit.infrastructure.adapter.input.rest.academic.dto;

import com.synaptixfit.domain.model.academic.AiDocument;
import com.synaptixfit.domain.model.academic.AiDocumentType;
import com.synaptixfit.domain.model.academic.ArtifactKind;
import com.synaptixfit.domain.model.academic.GeneratedStudyArtifact;
import com.synaptixfit.domain.model.academic.MindMap;
import com.synaptixfit.domain.model.academic.MindMapNode;
import com.synaptixfit.domain.model.academic.QuestionDraft;
import com.synaptixfit.domain.model.academic.QuestionType;
import com.synaptixfit.domain.model.academic.SavedQuiz;
import com.synaptixfit.domain.model.academic.StudyDocument;
import com.synaptixfit.domain.model.academic.StudySourceRef;
import com.synaptixfit.domain.model.academic.StudySourceType;
import com.synaptixfit.domain.model.academic.TeachingGuide;
import com.synaptixfit.domain.model.academic.TeachingGuideDocument;
import jakarta.validation.Valid;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.time.Instant;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;
import java.util.UUID;

/** DTOs del asistente de estudio con IA, el centro de generación y la guía docente. */
public final class StudyDtos {

    private StudyDtos() {
    }

    // ------------------------------------------------------------------ mapa mental

    public record MindMapNodeDto(@NotBlank @Size(max = 200) String title, @Valid List<MindMapNodeDto> children) {

        static MindMapNodeDto from(MindMapNode n) {
            return new MindMapNodeDto(n.title(), n.children().stream().map(MindMapNodeDto::from).toList());
        }

        MindMapNode toDomain() {
            return new MindMapNode(title, children == null ? List.of()
                    : children.stream().map(MindMapNodeDto::toDomain).toList());
        }
    }

    /** Mapa mental: tema central y ramas (profundidad máxima 3). */
    public record MindMapDto(@Size(max = 200) String central, @Valid @Size(max = 30) List<MindMapNodeDto> branches) {

        public static MindMapDto from(MindMap m) {
            return m == null ? null
                    : new MindMapDto(m.central(), m.branches().stream().map(MindMapNodeDto::from).toList());
        }

        public MindMap toDomain() {
            return new MindMap(central, branches == null ? List.of()
                    : branches.stream().map(MindMapNodeDto::toDomain).toList());
        }
    }

    // ------------------------------------------------------------------ documentos por fuente

    /**
     * Documento de IA guardado. Según {@code type}: {@code markdown} (SUMMARY), {@code mindMap}
     * (MIND_MAP) o {@code materialId}/{@code questionBankId}/{@code questionCount} (PRACTICE).
     */
    public record StudyDocumentResponse(UUID id, StudySourceType sourceType, UUID sourceId, AiDocumentType type,
                                        UUID subjectId, String sourceTitle, String markdown, MindMapDto mindMap,
                                        UUID materialId, UUID questionBankId, Integer questionCount,
                                        Instant createdAt, Instant updatedAt) {

        public static StudyDocumentResponse from(StudySourceType sourceType, UUID sourceId, StudyDocument d) {
            AiDocument doc = d.document();
            return new StudyDocumentResponse(doc.id(), sourceType, sourceId, doc.type(), doc.subjectId(),
                    doc.sourceTitle(), d.markdown(), MindMapDto.from(d.mindMap()), d.materialId(), d.questionBankId(),
                    d.questionCount(), doc.createdAt(), doc.updatedAt());
        }
    }

    /** Documentos de IA guardados de una fuente (para los iconos del cliente). */
    public record DocumentAvailabilityResponse(boolean summary, boolean mindMap, boolean practice,
                                               Set<AiDocumentType> types) {

        public static DocumentAvailabilityResponse from(Set<AiDocumentType> types) {
            return new DocumentAvailabilityResponse(types.contains(AiDocumentType.SUMMARY),
                    types.contains(AiDocumentType.MIND_MAP), types.contains(AiDocumentType.PRACTICE), types);
        }
    }

    // ------------------------------------------------------------------ centro de generación

    public record SourceRefDto(@NotNull StudySourceType type, @NotNull UUID id) {

        public StudySourceRef toDomain() {
            return new StudySourceRef(type, id);
        }
    }

    public record GenerateArtifactRequest(@NotNull ArtifactKind kind,
                                          @NotEmpty @Size(max = 10) List<@Valid @NotNull SourceRefDto> sources) {
    }

    public record FlashcardDto(String question, String answer) {
    }

    /** Pregunta de práctica (generada o enviada para guardarla). */
    public record QuestionDraftDto(@NotNull QuestionType type,
                                   @NotBlank @Size(max = 2000) String statement,
                                   @Size(max = 10) List<@Size(max = 500) String> options,
                                   @NotBlank @Size(max = 1000) String correctAnswer,
                                   @Size(max = 2000) String explanation) {

        public static QuestionDraftDto from(QuestionDraft d) {
            return new QuestionDraftDto(d.type(), d.statement(), d.options(), d.correctAnswer(), d.explanation());
        }

        public QuestionDraft toDomain() {
            return new QuestionDraft(type, statement, options, correctAnswer, explanation);
        }
    }

    /** Resultado efímero: solo se rellena el campo propio de {@code kind}. */
    public record ArtifactResponse(ArtifactKind kind, String title, String markdown, MindMapDto mindMap,
                                   List<FlashcardDto> flashcards, List<QuestionDraftDto> questions) {

        public static ArtifactResponse from(GeneratedStudyArtifact a) {
            return new ArtifactResponse(a.kind(), a.title(), a.markdown(), MindMapDto.from(a.mindMap()),
                    a.flashcards().stream().map(f -> new FlashcardDto(f.question(), f.answer())).toList(),
                    a.questions().stream().map(QuestionDraftDto::from).toList());
        }
    }

    /** Guardar como apunte: {@code markdown} o {@code mindMap} (que se serializa a Markdown). */
    public record SaveArtifactNoteRequest(UUID subjectId,
                                          @Size(max = 200) String title,
                                          @Size(max = 200_000) String markdown,
                                          @Valid MindMapDto mindMap) {
    }

    public record SaveQuizRequest(@NotNull UUID subjectId,
                                  @Size(max = 200) String title,
                                  @NotEmpty @Size(max = 50) List<@Valid @NotNull QuestionDraftDto> questions) {
    }

    public record SavedQuizResponse(UUID noteId, UUID materialId, UUID questionBankId, int questionCount) {

        public static SavedQuizResponse from(SavedQuiz q) {
            return new SavedQuizResponse(q.note().id(), q.material().id(), q.bank().id(), q.questionCount());
        }
    }

    // ------------------------------------------------------------------ guía docente

    public record GenerateTeachingGuideRequest(@NotNull UUID fileId) {
    }

    public record TopicUpdateRequest(@NotNull Boolean completed) {
    }

    /** Nota del criterio (0-10); null la borra. */
    public record AssessmentGradeRequest(@DecimalMin("0") @DecimalMax("10") Double grade) {
    }

    public record ProfessorDto(String name, String email, String office) {
    }

    public record TopicDto(int index, String title, TeachingGuide.TopicKind kind, boolean completed,
                           List<String> subtopics, Double hours) {
    }

    /** {@code active}: cuenta para la nota con la modalidad de evaluación activa. */
    public record AssessmentDto(int index, String name, double percentage, Double grade,
                                TeachingGuide.EvaluationMode mode, TeachingGuide.AssessmentKind kind,
                                Integer durationMinutes, List<Integer> topicNumbers, Boolean recoverable,
                                LocalDate dueDate, boolean active) {
    }

    public record GradeEstimateDto(double estimatedGrade, double coveredPercentage, Double requiredGradeToPass,
                                   String nextPendingAssessment) {
    }

    public record EvaluationModeRequest(@NotNull TeachingGuide.EvaluationMode mode) {
    }

    public record TeachingGuideResponse(UUID subjectId, TeachingGuideDtos.SubjectInfoDto subject,
                                        List<ProfessorDto> professors, List<TopicDto> topics,
                                        List<AssessmentDto> assessments, List<String> bibliography,
                                        List<TeachingGuide.EvaluationMode> availableModes,
                                        TeachingGuide.EvaluationMode effectiveMode,
                                        double syllabusProgress, GradeEstimateDto estimate, Instant updatedAt) {

        public static TeachingGuideResponse from(TeachingGuideDocument d) {
            TeachingGuide g = d.guide();
            List<TopicDto> topics = new ArrayList<>();
            for (int i = 0; i < g.topics().size(); i++) {
                TeachingGuide.Topic t = g.topics().get(i);
                topics.add(new TopicDto(i, t.title(), t.kind(), t.completed(), t.subtopics(), t.hours()));
            }
            List<AssessmentDto> assessments = new ArrayList<>();
            for (int i = 0; i < g.assessments().size(); i++) {
                TeachingGuide.Assessment a = g.assessments().get(i);
                assessments.add(new AssessmentDto(i, a.name(), a.percentage(), a.grade(), a.mode(), a.kind(),
                        a.durationMinutes(), a.topicNumbers(), a.recoverable(), a.dueDate(), g.isActive(a)));
            }
            TeachingGuide.GradeEstimate e = g.estimate();
            return new TeachingGuideResponse(d.subjectId(), TeachingGuideDtos.SubjectInfoDto.from(g.subject()),
                    g.professors().stream().map(p -> new ProfessorDto(p.name(), p.email(), p.office())).toList(),
                    topics, assessments, g.bibliography(), g.availableModes(), g.effectiveMode(),
                    g.syllabusProgress(),
                    new GradeEstimateDto(e.estimatedGrade(), e.coveredPercentage(), e.requiredGradeToPass(),
                            e.nextPendingAssessment()),
                    d.updatedAt());
        }
    }
}
