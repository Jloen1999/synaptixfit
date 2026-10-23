package com.synaptixfit.infrastructure.adapter.input.rest.academic;

import com.synaptixfit.application.port.input.academic.GenerateStudyArtifactUseCase;
import com.synaptixfit.application.port.input.academic.GenerateStudyDocumentUseCase;
import com.synaptixfit.application.port.input.academic.GetStudyDocumentAvailabilityUseCase;
import com.synaptixfit.application.port.input.academic.GetStudyDocumentUseCase;
import com.synaptixfit.application.port.input.academic.SaveArtifactAsNoteUseCase;
import com.synaptixfit.application.port.input.academic.SaveArtifactAsQuizUseCase;
import com.synaptixfit.domain.model.academic.AiDocumentType;
import com.synaptixfit.domain.model.academic.StudySourceType;
import com.synaptixfit.infrastructure.adapter.input.rest.academic.dto.NoteDtos.NoteResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.academic.dto.StudyDtos.ArtifactResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.academic.dto.StudyDtos.DocumentAvailabilityResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.academic.dto.StudyDtos.GenerateArtifactRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.academic.dto.StudyDtos.QuestionDraftDto;
import com.synaptixfit.infrastructure.adapter.input.rest.academic.dto.StudyDtos.SaveArtifactNoteRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.academic.dto.StudyDtos.SaveQuizRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.academic.dto.StudyDtos.SavedQuizResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.academic.dto.StudyDtos.SourceRefDto;
import com.synaptixfit.infrastructure.adapter.input.rest.academic.dto.StudyDtos.StudyDocumentResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.support.CurrentUserId;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/**
 * Asistente de estudio con IA. Documentos por fuente con «cargar o generar» (GET devuelve el
 * guardado; POST genera o regenera y lo guarda) y centro de generación multi-fuente (efímero).
 */
@Tag(name = "Academic - Study assistant")
@RestController
@RequestMapping("/api/v1/study")
public class StudyAssistantController {

    private final GetStudyDocumentUseCase getDocument;
    private final GenerateStudyDocumentUseCase generateDocument;
    private final GetStudyDocumentAvailabilityUseCase availability;
    private final GenerateStudyArtifactUseCase generateArtifact;
    private final SaveArtifactAsNoteUseCase saveAsNote;
    private final SaveArtifactAsQuizUseCase saveAsQuiz;

    public StudyAssistantController(GetStudyDocumentUseCase getDocument, GenerateStudyDocumentUseCase generateDocument,
                                    GetStudyDocumentAvailabilityUseCase availability,
                                    GenerateStudyArtifactUseCase generateArtifact, SaveArtifactAsNoteUseCase saveAsNote,
                                    SaveArtifactAsQuizUseCase saveAsQuiz) {
        this.getDocument = getDocument;
        this.generateDocument = generateDocument;
        this.availability = availability;
        this.generateArtifact = generateArtifact;
        this.saveAsNote = saveAsNote;
        this.saveAsQuiz = saveAsQuiz;
    }

    @GetMapping("/sources/{sourceType}/{sourceId}/documents")
    public DocumentAvailabilityResponse availability(@CurrentUserId UUID userId,
                                                     @PathVariable StudySourceType sourceType,
                                                     @PathVariable UUID sourceId) {
        return DocumentAvailabilityResponse.from(availability.availableDocuments(userId, sourceType, sourceId));
    }

    @GetMapping("/sources/{sourceType}/{sourceId}/documents/{type}")
    public StudyDocumentResponse get(@CurrentUserId UUID userId, @PathVariable StudySourceType sourceType,
                                     @PathVariable UUID sourceId, @PathVariable AiDocumentType type) {
        return StudyDocumentResponse.from(sourceType, sourceId,
                getDocument.getDocument(userId, sourceType, sourceId, type));
    }

    @PostMapping("/sources/{sourceType}/{sourceId}/documents/{type}")
    @ResponseStatus(HttpStatus.CREATED)
    public StudyDocumentResponse generate(@CurrentUserId UUID userId, @PathVariable StudySourceType sourceType,
                                          @PathVariable UUID sourceId, @PathVariable AiDocumentType type) {
        return StudyDocumentResponse.from(sourceType, sourceId,
                generateDocument.generateDocument(userId, sourceType, sourceId, type));
    }

    @PostMapping("/generations")
    public ArtifactResponse generateArtifact(@CurrentUserId UUID userId,
                                             @Valid @RequestBody GenerateArtifactRequest r) {
        return ArtifactResponse.from(generateArtifact.generate(new GenerateStudyArtifactUseCase.Command(userId,
                r.kind(), r.sources().stream().map(SourceRefDto::toDomain).toList())));
    }

    @PostMapping("/generations/notes")
    @ResponseStatus(HttpStatus.CREATED)
    public NoteResponse saveAsNote(@CurrentUserId UUID userId, @Valid @RequestBody SaveArtifactNoteRequest r) {
        return NoteResponse.from(saveAsNote.saveAsNote(new SaveArtifactAsNoteUseCase.Command(userId, r.subjectId(),
                r.title(), r.markdown(), r.mindMap() == null ? null : r.mindMap().toDomain())));
    }

    @PostMapping("/generations/quizzes")
    @ResponseStatus(HttpStatus.CREATED)
    public SavedQuizResponse saveAsQuiz(@CurrentUserId UUID userId, @Valid @RequestBody SaveQuizRequest r) {
        return SavedQuizResponse.from(saveAsQuiz.saveAsQuiz(new SaveArtifactAsQuizUseCase.Command(userId,
                r.subjectId(), r.title(), r.questions().stream().map(QuestionDraftDto::toDomain).toList())));
    }
}
