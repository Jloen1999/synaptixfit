package com.synaptixfit.application.service.academic;

import com.synaptixfit.application.port.input.academic.GenerateStudyArtifactUseCase;
import com.synaptixfit.application.port.input.academic.GenerateStudyDocumentUseCase;
import com.synaptixfit.application.port.input.academic.GenerateTeachingGuideUseCase;
import com.synaptixfit.application.port.input.academic.GetStudyDocumentAvailabilityUseCase;
import com.synaptixfit.application.port.input.academic.GetStudyDocumentUseCase;
import com.synaptixfit.application.port.input.academic.GetTeachingGuideUseCase;
import com.synaptixfit.application.port.input.academic.GradeTeachingGuideAssessmentUseCase;
import com.synaptixfit.application.port.input.academic.SaveArtifactAsNoteUseCase;
import com.synaptixfit.application.port.input.academic.SaveArtifactAsQuizUseCase;
import com.synaptixfit.application.port.input.academic.SetTeachingGuideModeUseCase;
import com.synaptixfit.application.port.input.academic.UpdateTeachingGuideTopicUseCase;
import com.synaptixfit.domain.exception.AiUnavailableException;
import com.synaptixfit.domain.exception.FieldValidationException;
import com.synaptixfit.domain.exception.academic.AiDocumentNotFoundException;
import com.synaptixfit.domain.exception.academic.StudySourceNotSupportedException;
import com.synaptixfit.domain.exception.academic.SubjectFileNotFoundException;
import com.synaptixfit.domain.exception.academic.TeachingGuideEmptyException;
import com.synaptixfit.domain.model.academic.AiDocument;
import com.synaptixfit.domain.model.academic.AiDocumentSource;
import com.synaptixfit.domain.model.academic.AiDocumentType;
import com.synaptixfit.domain.model.academic.GeneratedStudyArtifact;
import com.synaptixfit.domain.model.academic.MindMap;
import com.synaptixfit.domain.model.academic.Note;
import com.synaptixfit.domain.model.academic.Question;
import com.synaptixfit.domain.model.academic.QuestionBank;
import com.synaptixfit.domain.model.academic.QuestionDraft;
import com.synaptixfit.domain.model.academic.SavedQuiz;
import com.synaptixfit.domain.model.academic.StudyDocument;
import com.synaptixfit.domain.model.academic.StudyMaterial;
import com.synaptixfit.domain.model.academic.StudySourceRef;
import com.synaptixfit.domain.model.academic.StudySourceType;
import com.synaptixfit.domain.model.academic.Subject;
import com.synaptixfit.domain.model.academic.SubjectFile;
import com.synaptixfit.domain.model.academic.TeachingGuide;
import com.synaptixfit.domain.model.academic.TeachingGuideDocument;
import com.synaptixfit.domain.model.shared.Guard;
import com.synaptixfit.domain.model.shared.Visibility;
import com.synaptixfit.domain.port.output.academic.AiDocumentRepositoryPort;
import com.synaptixfit.domain.port.output.academic.NoteRepositoryPort;
import com.synaptixfit.domain.port.output.academic.QuestionBankRepositoryPort;
import com.synaptixfit.domain.port.output.academic.StudyAssistantPort;
import com.synaptixfit.domain.port.output.academic.StudyDocumentCodecPort;
import com.synaptixfit.domain.port.output.academic.StudyMaterialRepositoryPort;
import com.synaptixfit.domain.port.output.academic.SubjectFileRepositoryPort;
import com.synaptixfit.domain.port.output.academic.SubjectRepositoryPort;
import com.synaptixfit.domain.port.output.storage.FileStoragePort;
import java.time.Clock;
import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;

/**
 * Asistente de estudio con IA: documentos por fuente con persistencia «cargar o generar»,
 * centro de generación multi-fuente (efímero) y guía docente de la asignatura.
 */
public class StudyAssistantService implements GetStudyDocumentUseCase, GenerateStudyDocumentUseCase,
        GetStudyDocumentAvailabilityUseCase, GenerateStudyArtifactUseCase, SaveArtifactAsNoteUseCase,
        SaveArtifactAsQuizUseCase, GetTeachingGuideUseCase, GenerateTeachingGuideUseCase,
        UpdateTeachingGuideTopicUseCase, GradeTeachingGuideAssessmentUseCase, SetTeachingGuideModeUseCase {

    static final int MAX_SOURCES = 10;
    static final int MAX_SAVED_QUESTIONS = 50;

    private final NoteRepositoryPort notes;
    private final StudyMaterialRepositoryPort materials;
    private final QuestionBankRepositoryPort banks;
    private final AiDocumentRepositoryPort aiDocuments;
    private final StudyDocumentCodecPort codec;
    private final StudyAssistantPort assistant;
    private final FileStoragePort storage;
    private final Clock clock;
    private final AcademicLookups lookups;
    private final PracticeBankGenerator practiceBanks;

    public StudyAssistantService(SubjectRepositoryPort subjects, NoteRepositoryPort notes,
                                 SubjectFileRepositoryPort files, StudyMaterialRepositoryPort materials,
                                 QuestionBankRepositoryPort banks, AiDocumentRepositoryPort aiDocuments,
                                 StudyDocumentCodecPort codec, StudyAssistantPort assistant, FileStoragePort storage,
                                 Clock clock) {
        this.notes = notes;
        this.materials = materials;
        this.banks = banks;
        this.aiDocuments = aiDocuments;
        this.codec = codec;
        this.assistant = assistant;
        this.storage = storage;
        this.clock = clock;
        this.lookups = new AcademicLookups(subjects, notes, files, materials, storage, clock);
        this.practiceBanks = new PracticeBankGenerator(banks, aiDocuments, codec, assistant, clock);
    }

    // ------------------------------------------------------------------ documentos por fuente

    @Override
    public StudyDocument getDocument(UUID userId, StudySourceType sourceType, UUID sourceId, AiDocumentType type) {
        requireSourceDocumentType(type);
        lookups.origin(userId, sourceType, sourceId);
        AiDocument doc = aiDocuments.find(userId, AiDocumentSource.of(sourceType), sourceId.toString(), type)
                .orElseThrow(() -> new AiDocumentNotFoundException(sourceType + "/" + sourceId + "/" + type));
        return toStudyDocument(doc);
    }

    @Override
    public StudyDocument generateDocument(UUID userId, StudySourceType sourceType, UUID sourceId,
                                          AiDocumentType type) {
        requireSourceDocumentType(type);
        StudySourceRef ref = new StudySourceRef(sourceType, sourceId);
        if (type == AiDocumentType.PRACTICE) {
            StudyMaterial material = lookups.ensureMaterial(userId, sourceType, sourceId);
            return toStudyDocument(practiceBanks.generate(userId, material, lookups.resolve(userId, ref)));
        }
        AcademicLookups.ResolvedSource source = lookups.resolve(userId, ref);
        String content = switch (type) {
            case SUMMARY -> {
                StudyAssistantPort.Summary summary = assistant.summarize(List.of(source.source()));
                if (summary.markdown() == null || summary.markdown().isBlank()) {
                    throw new AiUnavailableException("AI returned an empty summary");
                }
                yield summary.markdown();
            }
            case MIND_MAP -> {
                MindMap map = assistant.mindMap(List.of(source.source())).mindMap();
                if (map == null || map.isEmpty()) {
                    throw new AiUnavailableException("AI returned an empty mind map");
                }
                yield codec.encodeMindMap(map);
            }
            default -> throw new FieldValidationException("type", "INVALID", "unsupported document type");
        };
        return toStudyDocument(upsert(userId, source.subjectId(), AiDocumentSource.of(sourceType),
                sourceId.toString(), type, source.title(), content));
    }

    @Override
    public Set<AiDocumentType> availableDocuments(UUID userId, StudySourceType sourceType, UUID sourceId) {
        lookups.origin(userId, sourceType, sourceId);
        return aiDocuments.typesFor(userId, AiDocumentSource.of(sourceType), sourceId.toString());
    }

    // ------------------------------------------------------------------ centro de generación

    @Override
    public GeneratedStudyArtifact generate(GenerateStudyArtifactUseCase.Command c) {
        Guard.notNull(c.kind(), "kind");
        List<StudySourceRef> refs = c.sources() == null ? List.of() : List.copyOf(new LinkedHashSet<>(c.sources()));
        if (refs.isEmpty() || refs.size() > MAX_SOURCES) {
            throw new FieldValidationException("sources", "INVALID_LENGTH",
                    "between 1 and " + MAX_SOURCES + " sources are required");
        }
        List<StudyAssistantPort.Source> sources = refs.stream()
                .map(ref -> lookups.resolve(c.userId(), ref).source()).toList();
        return switch (c.kind()) {
            case SUMMARY -> {
                StudyAssistantPort.Summary s = assistant.summarize(sources);
                if (s.markdown() == null || s.markdown().isBlank()) {
                    throw new AiUnavailableException("AI returned an empty summary");
                }
                yield new GeneratedStudyArtifact(c.kind(), titleOr(s.title(), "Resumen"), s.markdown(), null,
                        null, null);
            }
            case MIND_MAP -> {
                StudyAssistantPort.GeneratedMindMap m = assistant.mindMap(sources);
                if (m.mindMap() == null || m.mindMap().isEmpty()) {
                    throw new AiUnavailableException("AI returned an empty mind map");
                }
                yield new GeneratedStudyArtifact(c.kind(), titleOr(m.title(), m.mindMap().central()), null,
                        m.mindMap(), null, null);
            }
            case FLASHCARDS -> {
                StudyAssistantPort.Flashcards f = assistant.flashcards(sources);
                if (f.cards().isEmpty()) {
                    throw new AiUnavailableException("AI returned no flashcards");
                }
                yield new GeneratedStudyArtifact(c.kind(), titleOr(f.title(), "Tarjetas de estudio"), null, null,
                        f.cards().stream().map(card -> new GeneratedStudyArtifact.Flashcard(card.question(),
                                card.answer())).toList(), null);
            }
            case PRACTICE_TEST -> {
                StudyAssistantPort.PracticeQuestions p = assistant.practiceQuestions(sources);
                if (p.questions().isEmpty()) {
                    throw new AiUnavailableException("AI returned no questions");
                }
                yield new GeneratedStudyArtifact(c.kind(), titleOr(p.title(), "Cuestionario"), null, null, null,
                        p.questions());
            }
        };
    }

    @Override
    public Note saveAsNote(SaveArtifactAsNoteUseCase.Command c) {
        if (c.subjectId() != null) {
            lookups.subject(c.userId(), c.subjectId());
        }
        String content;
        if (c.mindMap() != null) {
            content = c.mindMap().toMarkdown();
        } else {
            content = Guard.notBlank(c.markdown(), "markdown");
        }
        String title = titleOr(c.title(), c.mindMap() != null ? c.mindMap().central() : "Resumen");
        return notes.save(Note.create(c.userId(), c.subjectId(), truncate(title, 200), content, Visibility.PRIVATE,
                false, clock.instant()));
    }

    @Override
    public SavedQuiz saveAsQuiz(SaveArtifactAsQuizUseCase.Command c) {
        Subject subject = lookups.subject(c.userId(), Guard.notNull(c.subjectId(), "subjectId"));
        List<QuestionDraft> drafts = c.questions() == null ? List.of() : c.questions();
        if (drafts.isEmpty() || drafts.size() > MAX_SAVED_QUESTIONS) {
            throw new FieldValidationException("questions", "INVALID_LENGTH",
                    "between 1 and " + MAX_SAVED_QUESTIONS + " questions are required");
        }
        String title = truncate(titleOr(c.title(), "Cuestionario"), 200);
        // El material envuelve un apunte con el cuestionario en Markdown (la tabla solo admite
        // apuntes o archivos como origen; el sistema antiguo usaba un tipo inválido).
        Note note = notes.save(Note.create(c.userId(), subject.id(), title, quizMarkdown(title, drafts),
                Visibility.PRIVATE, false, clock.instant()));
        StudyMaterial material = materials.save(StudyMaterial.create(c.userId(), subject.id(), StudySourceType.NOTE,
                note.id(), title, clock.instant()));
        QuestionBank bank = banks.save(QuestionBank.create(material.id(), c.userId(), clock.instant()));
        List<Question> questions = new ArrayList<>();
        for (int i = 0; i < drafts.size(); i++) {
            questions.add(Question.from(drafts.get(i), bank.id(), i));
        }
        banks.replaceQuestions(bank.id(), questions);
        return new SavedQuiz(note, material, bank, questions.size());
    }

    // ------------------------------------------------------------------ guía docente

    @Override
    public TeachingGuideDocument getTeachingGuide(UUID userId, UUID subjectId) {
        Subject s = lookups.subject(userId, subjectId);
        return toGuide(s.id(), guideDocument(userId, s.id()));
    }

    @Override
    public TeachingGuideDocument generateTeachingGuide(UUID userId, UUID subjectId, UUID fileId) {
        Subject s = lookups.subject(userId, subjectId);
        SubjectFile file = lookups.file(userId, Guard.notNull(fileId, "fileId"));
        if (!file.subjectId().equals(s.id())) {
            throw new SubjectFileNotFoundException(fileId);
        }
        if (!file.isAiReadable()) {
            throw new StudySourceNotSupportedException(file.mimeType());
        }
        byte[] data = storage.download(file.objectKey());
        TeachingGuide guide = assistant.extractTeachingGuide(
                StudyAssistantPort.Source.binary(file.fileName(), file.mimeType(), data));
        if (guide == null || !guide.hasData()) {
            throw new TeachingGuideEmptyException(fileId);
        }
        TeachingGuide previous = aiDocuments.find(userId, AiDocumentSource.SUBJECT, s.id().toString(),
                AiDocumentType.TEACHING_GUIDE).map(d -> codec.decodeTeachingGuide(d.content())).orElse(null);
        guide = guide.keepingProgressOf(previous);
        AiDocument doc = upsert(userId, s.id(), AiDocumentSource.SUBJECT, s.id().toString(),
                AiDocumentType.TEACHING_GUIDE, s.name(), codec.encodeTeachingGuide(guide));
        return toGuide(s.id(), doc);
    }

    @Override
    public TeachingGuideDocument setTopicCompleted(UUID userId, UUID subjectId, int topicIndex, boolean completed) {
        Subject s = lookups.subject(userId, subjectId);
        AiDocument doc = guideDocument(userId, s.id());
        TeachingGuide updated = codec.decodeTeachingGuide(doc.content()).withTopicCompleted(topicIndex, completed);
        return toGuide(s.id(), aiDocuments.save(doc.withContent(codec.encodeTeachingGuide(updated), null, s.id(),
                clock.instant())));
    }

    @Override
    public TeachingGuideDocument setAssessmentGrade(UUID userId, UUID subjectId, int assessmentIndex, Double grade) {
        Subject s = lookups.subject(userId, subjectId);
        AiDocument doc = guideDocument(userId, s.id());
        TeachingGuide updated = codec.decodeTeachingGuide(doc.content()).withGrade(assessmentIndex, grade);
        return toGuide(s.id(), aiDocuments.save(doc.withContent(codec.encodeTeachingGuide(updated), null, s.id(),
                clock.instant())));
    }

    @Override
    public TeachingGuideDocument setMode(UUID userId, UUID subjectId, TeachingGuide.EvaluationMode mode) {
        Subject s = lookups.subject(userId, subjectId);
        AiDocument doc = guideDocument(userId, s.id());
        TeachingGuide updated = codec.decodeTeachingGuide(doc.content()).withSelectedMode(mode);
        return toGuide(s.id(), aiDocuments.save(doc.withContent(codec.encodeTeachingGuide(updated), null, s.id(),
                clock.instant())));
    }

    // ------------------------------------------------------------------ apoyo

    private AiDocument upsert(UUID userId, UUID subjectId, AiDocumentSource source, String sourceId,
                              AiDocumentType type, String title, String content) {
        AiDocument doc = aiDocuments.find(userId, source, sourceId, type)
                .map(d -> d.withContent(content, title, subjectId, clock.instant()))
                .orElseGet(() -> AiDocument.create(userId, subjectId, source, sourceId, type, title, content,
                        clock.instant()));
        return aiDocuments.save(doc);
    }

    private AiDocument guideDocument(UUID userId, UUID subjectId) {
        return aiDocuments.find(userId, AiDocumentSource.SUBJECT, subjectId.toString(), AiDocumentType.TEACHING_GUIDE)
                .orElseThrow(() -> new AiDocumentNotFoundException("SUBJECT/" + subjectId + "/TEACHING_GUIDE"));
    }

    private TeachingGuideDocument toGuide(UUID subjectId, AiDocument doc) {
        return new TeachingGuideDocument(subjectId, codec.decodeTeachingGuide(doc.content()), doc.updatedAt());
    }

    private StudyDocument toStudyDocument(AiDocument doc) {
        return switch (doc.type()) {
            case SUMMARY -> new StudyDocument(doc, doc.content(), null, null, null, null);
            case MIND_MAP -> new StudyDocument(doc, null, codec.decodeMindMap(doc.content()), null, null, null);
            case PRACTICE -> {
                StudyDocumentCodecPort.PracticeMarker m = codec.decodePractice(doc.content());
                yield new StudyDocument(doc, null, null, m.materialId(), m.bankId(), m.questionCount());
            }
            case TEACHING_GUIDE -> new StudyDocument(doc, null, null, null, null, null);
        };
    }

    private static void requireSourceDocumentType(AiDocumentType type) {
        if (type == null || type == AiDocumentType.TEACHING_GUIDE) {
            throw new FieldValidationException("type", "INVALID",
                    "only SUMMARY, MIND_MAP and PRACTICE apply to notes and files");
        }
    }

    static String quizMarkdown(String title, List<QuestionDraft> drafts) {
        StringBuilder sb = new StringBuilder("# ").append(title).append("\n\n");
        for (int i = 0; i < drafts.size(); i++) {
            QuestionDraft d = drafts.get(i);
            sb.append("## ").append(i + 1).append(". ").append(d.statement()).append('\n');
            for (String option : d.options()) {
                sb.append("- ").append(option).append('\n');
            }
            sb.append("\n**Respuesta:** ").append(d.correctAnswer()).append('\n');
            if (d.explanation() != null) {
                sb.append("\n_").append(d.explanation()).append("_\n");
            }
            sb.append('\n');
        }
        return sb.toString().strip() + "\n";
    }

    private static String titleOr(String title, String fallback) {
        return title == null || title.isBlank() ? fallback : title.strip();
    }

    private static String truncate(String value, int max) {
        return value.length() > max ? value.substring(0, max) : value;
    }
}
