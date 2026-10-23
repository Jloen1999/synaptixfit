package com.synaptixfit.application.service.academic;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.synaptixfit.application.port.input.academic.GenerateStudyArtifactUseCase;
import com.synaptixfit.application.port.input.academic.SaveArtifactAsNoteUseCase;
import com.synaptixfit.application.port.input.academic.SaveArtifactAsQuizUseCase;
import com.synaptixfit.domain.exception.AiUnavailableException;
import com.synaptixfit.domain.exception.FieldValidationException;
import com.synaptixfit.domain.exception.academic.AiDocumentNotFoundException;
import com.synaptixfit.domain.exception.academic.NoteNotFoundException;
import com.synaptixfit.domain.exception.academic.StudySourceNotSupportedException;
import com.synaptixfit.domain.exception.academic.StudySourceWithoutSubjectException;
import com.synaptixfit.domain.exception.academic.TeachingGuideEmptyException;
import com.synaptixfit.domain.model.academic.AiDocumentType;
import com.synaptixfit.domain.model.academic.ArtifactKind;
import com.synaptixfit.domain.model.academic.GeneratedStudyArtifact;
import com.synaptixfit.domain.model.academic.MindMap;
import com.synaptixfit.domain.model.academic.MindMapNode;
import com.synaptixfit.domain.model.academic.Note;
import com.synaptixfit.domain.model.academic.QuestionDraft;
import com.synaptixfit.domain.model.academic.QuestionType;
import com.synaptixfit.domain.model.academic.SavedQuiz;
import com.synaptixfit.domain.model.academic.StudyDocument;
import com.synaptixfit.domain.model.academic.StudySourceRef;
import com.synaptixfit.domain.model.academic.StudySourceType;
import com.synaptixfit.domain.model.academic.Subject;
import com.synaptixfit.domain.model.academic.SubjectFile;
import com.synaptixfit.domain.model.academic.TeachingGuide;
import com.synaptixfit.domain.model.academic.TeachingGuideDocument;
import com.synaptixfit.domain.port.output.academic.StudyAssistantPort;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class StudyAssistantServiceTest {

    private final AcademicFakes f = new AcademicFakes();
    private final StudyAssistantPort assistant = mock(StudyAssistantPort.class);
    private final StudyAssistantService service = new StudyAssistantService(f.subjects, f.notes, f.files,
            f.materials, f.banks, f.aiDocuments, f.codec, assistant, f.storage, AcademicFakes.CLOCK);
    private final UUID user = UUID.randomUUID();
    private final UUID stranger = UUID.randomUUID();

    @Test
    void summaryIsLoadedOrGeneratedAndRegenerationOverwrites() {
        Subject s = f.subject(user, "Economía");
        Note n = f.note(user, s.id(), "Oferta");
        when(assistant.summarize(anyList())).thenReturn(new StudyAssistantPort.Summary("Oferta", "## v1"),
                new StudyAssistantPort.Summary("Oferta", "## v2"));

        assertThatThrownBy(() -> service.getDocument(user, StudySourceType.NOTE, n.id(), AiDocumentType.SUMMARY))
                .isInstanceOf(AiDocumentNotFoundException.class);
        service.generateDocument(user, StudySourceType.NOTE, n.id(), AiDocumentType.SUMMARY);
        StudyDocument second = service.generateDocument(user, StudySourceType.NOTE, n.id(), AiDocumentType.SUMMARY);

        assertThat(f.docStore).hasSize(1);
        assertThat(second.markdown()).isEqualTo("## v2");
        assertThat(service.getDocument(user, StudySourceType.NOTE, n.id(), AiDocumentType.SUMMARY).markdown())
                .isEqualTo("## v2");
        assertThat(service.availableDocuments(user, StudySourceType.NOTE, n.id()))
                .containsExactly(AiDocumentType.SUMMARY);
        assertThatThrownBy(() -> service.generateDocument(stranger, StudySourceType.NOTE, n.id(),
                AiDocumentType.SUMMARY)).isInstanceOf(NoteNotFoundException.class);
    }

    @Test
    void fileSourcesMustBeAiReadableAndAreSentAsBinary() {
        Subject s = f.subject(user, "Economía");
        SubjectFile slides = f.file(user, s.id(), "tema.pptx",
                "application/vnd.openxmlformats-officedocument.presentationml.presentation");
        SubjectFile pdf = f.file(user, s.id(), "tema.pdf", "application/pdf");
        MindMap map = new MindMap("Mercados", List.of(new MindMapNode("Oferta", List.of())));
        when(assistant.mindMap(anyList())).thenAnswer(inv -> {
            List<StudyAssistantPort.Source> sources = inv.getArgument(0);
            assertThat(sources.getFirst().isBinary()).isTrue();
            assertThat(sources.getFirst().mimeType()).isEqualTo("application/pdf");
            return new StudyAssistantPort.GeneratedMindMap("Mercados", map);
        });

        assertThatThrownBy(() -> service.generateDocument(user, StudySourceType.FILE, slides.id(),
                AiDocumentType.MIND_MAP)).isInstanceOf(StudySourceNotSupportedException.class);
        StudyDocument doc = service.generateDocument(user, StudySourceType.FILE, pdf.id(), AiDocumentType.MIND_MAP);
        assertThat(doc.mindMap()).isEqualTo(map);
        assertThatThrownBy(() -> service.generateDocument(user, StudySourceType.FILE, pdf.id(),
                AiDocumentType.TEACHING_GUIDE)).isInstanceOf(FieldValidationException.class);
    }

    @Test
    void practiceDocumentCreatesMaterialAndBankButNeedsSubject() {
        Subject s = f.subject(user, "Economía");
        Note n = f.note(user, s.id(), "Demanda");
        when(assistant.practiceQuestions(anyList())).thenReturn(new StudyAssistantPort.PracticeQuestions("Demanda",
                List.of(new QuestionDraft(QuestionType.FILL_IN_BLANK, "La ___", null, "demanda", null))));

        StudyDocument doc = service.generateDocument(user, StudySourceType.NOTE, n.id(), AiDocumentType.PRACTICE);

        assertThat(doc.questionCount()).isEqualTo(1);
        assertThat(f.materialStore).containsKey(doc.materialId());
        assertThat(f.bankStore).containsKey(doc.questionBankId());

        Note loose = f.note(user, null, "Sin asignatura");
        assertThatThrownBy(() -> service.generateDocument(user, StudySourceType.NOTE, loose.id(),
                AiDocumentType.PRACTICE)).isInstanceOf(StudySourceWithoutSubjectException.class);
    }

    @Test
    void multiSourceArtifactIsEphemeralAndValidatesSources() {
        Subject s = f.subject(user, "Economía");
        Note a = f.note(user, s.id(), "A");
        Note b = f.note(user, s.id(), "B");
        when(assistant.flashcards(anyList())).thenReturn(new StudyAssistantPort.Flashcards("Mercado",
                List.of(new StudyAssistantPort.Flashcard("¿Qué es?", "Esto"))));

        GeneratedStudyArtifact artifact = service.generate(new GenerateStudyArtifactUseCase.Command(user,
                ArtifactKind.FLASHCARDS, List.of(new StudySourceRef(StudySourceType.NOTE, a.id()),
                new StudySourceRef(StudySourceType.NOTE, b.id()))));
        assertThat(artifact.flashcards()).hasSize(1);
        assertThat(f.docStore).isEmpty();

        assertThatThrownBy(() -> service.generate(new GenerateStudyArtifactUseCase.Command(user, ArtifactKind.SUMMARY,
                List.of()))).isInstanceOf(FieldValidationException.class);
        when(assistant.summarize(anyList())).thenReturn(new StudyAssistantPort.Summary("x", " "));
        assertThatThrownBy(() -> service.generate(new GenerateStudyArtifactUseCase.Command(user, ArtifactKind.SUMMARY,
                List.of(new StudySourceRef(StudySourceType.NOTE, a.id()))))).isInstanceOf(AiUnavailableException.class);
    }

    @Test
    void savingArtifactsCreatesNotesMaterialsAndBanks() {
        Subject s = f.subject(user, "Economía");
        MindMap map = new MindMap("Mercado", List.of(new MindMapNode("Oferta", List.of(new MindMapNode("Curva",
                List.of())))));
        Note fromMap = service.saveAsNote(new SaveArtifactAsNoteUseCase.Command(user, s.id(), null, null, map));
        assertThat(fromMap.title()).isEqualTo("Mercado");
        assertThat(fromMap.content()).isEqualTo("# Mercado\n\n## Oferta\n- Curva\n");

        SavedQuiz quiz = service.saveAsQuiz(new SaveArtifactAsQuizUseCase.Command(user, s.id(), "Test", List.of(
                new QuestionDraft(QuestionType.MULTIPLE_CHOICE, "¿Precio?", List.of("Sube", "Baja"), "Sube", "Ley"))));
        assertThat(quiz.material().originId()).isEqualTo(quiz.note().id());
        assertThat(quiz.questionCount()).isEqualTo(1);
        assertThat(quiz.note().content()).contains("**Respuesta:** Sube");
        assertThat(f.questionStore).hasSize(1);

        assertThatThrownBy(() -> service.saveAsQuiz(new SaveArtifactAsQuizUseCase.Command(stranger, s.id(), "x",
                List.of()))).hasFieldOrPropertyWithValue("code", "SUBJECT_NOT_FOUND");
    }

    @Test
    void teachingGuideIsExtractedFromSubjectFileAndEditable() {
        Subject s = f.subject(user, "Economía");
        SubjectFile pdf = f.file(user, s.id(), "guia.pdf", "application/pdf");
        Subject other = f.subject(user, "Otra");
        SubjectFile otherPdf = f.file(user, other.id(), "otra.pdf", "application/pdf");
        TeachingGuide guide = new TeachingGuide(List.of(new TeachingGuide.Professor("Ana", "a@u.es", "D1")),
                List.of(new TeachingGuide.Topic("Tema 1", TeachingGuide.TopicKind.THEORY, false)),
                List.of(new TeachingGuide.Assessment("Examen", 100, null)), List.of());
        when(assistant.extractTeachingGuide(any())).thenReturn(guide);

        assertThatThrownBy(() -> service.generateTeachingGuide(user, s.id(), otherPdf.id()))
                .hasFieldOrPropertyWithValue("code", "FILE_NOT_FOUND");
        TeachingGuideDocument doc = service.generateTeachingGuide(user, s.id(), pdf.id());
        assertThat(doc.guide().professors()).hasSize(1);

        TeachingGuideDocument done = service.setTopicCompleted(user, s.id(), 0, true);
        assertThat(done.guide().syllabusProgress()).isEqualTo(1.0);
        TeachingGuideDocument graded = service.setAssessmentGrade(user, s.id(), 0, 7.5);
        assertThat(graded.guide().estimate().estimatedGrade()).isEqualTo(7.5);
        assertThat(service.getTeachingGuide(user, s.id()).guide().topics().getFirst().completed()).isTrue();

        when(assistant.extractTeachingGuide(any())).thenReturn(new TeachingGuide(null, null, null, null));
        assertThatThrownBy(() -> service.generateTeachingGuide(user, s.id(), pdf.id()))
                .isInstanceOf(TeachingGuideEmptyException.class);
        verify(assistant, never()).summarize(anyList());
    }
}
