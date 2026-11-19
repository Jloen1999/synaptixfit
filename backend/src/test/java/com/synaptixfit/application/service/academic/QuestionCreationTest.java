package com.synaptixfit.application.service.academic;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.synaptixfit.application.port.input.academic.GenerateQuestionBankUseCase;
import com.synaptixfit.domain.exception.AiUnavailableException;
import com.synaptixfit.domain.model.academic.BankUpdateMode;
import com.synaptixfit.domain.model.academic.DocumentQuestion;
import com.synaptixfit.domain.model.academic.DocumentQuestionScan;
import com.synaptixfit.domain.model.academic.Note;
import com.synaptixfit.domain.model.academic.Question;
import com.synaptixfit.domain.model.academic.QuestionBankGeneration;
import com.synaptixfit.domain.model.academic.QuestionBatch;
import com.synaptixfit.domain.model.academic.QuestionDraft;
import com.synaptixfit.domain.model.academic.QuestionFormat;
import com.synaptixfit.domain.model.academic.QuestionType;
import com.synaptixfit.domain.model.academic.StudyMaterial;
import com.synaptixfit.domain.model.academic.Subject;
import com.synaptixfit.domain.port.output.academic.StudyAssistantPort;
import java.util.ArrayList;
import java.util.List;
import java.util.Random;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicInteger;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/** «Crear preguntas» por tandas y lectura de las preguntas del documento (ADR 0058). */
class QuestionCreationTest {

    private final AcademicFakes f = new AcademicFakes();
    private final StudyAssistantPort assistant = mock(StudyAssistantPort.class);
    private final QuizService quiz = new QuizService(f.banks, f.attempts, f.sessions, f.materials, f.subjects,
            f.notes, f.files, f.aiDocuments, f.codec, assistant, f.storage, f.award, f.events::add, AcademicFakes.CLOCK,
            new Random(7));
    private final QuestionCreationService service = new QuestionCreationService(f.banks, f.materials, f.subjects,
            f.notes, f.files, f.aiDocuments, f.codec, assistant, f.storage, quiz, quiz, AcademicFakes.CLOCK);
    private final UUID user = UUID.randomUUID();
    private final AtomicInteger counter = new AtomicInteger();
    private StudyMaterial material;
    private Subject subject;

    @BeforeEach
    void setUp() {
        subject = f.subject(user, "Bases de datos");
        material = f.material(user, subject.id(), f.note(user, subject.id(), "SQL").id());
    }

    /** La IA devuelve justo las de la tanda, con enunciados distintos. */
    private void aiCreatesWhatIsAsked() {
        when(assistant.practiceQuestions(anyList(), any(QuestionBatch.class), anyList())).thenAnswer(inv -> {
            QuestionBatch batch = inv.getArgument(1);
            List<QuestionDraft> out = new ArrayList<>();
            for (int i = 0; i < batch.total(); i++) {
                out.add(fill("Pregunta nueva " + counter.incrementAndGet()));
            }
            return new StudyAssistantPort.PracticeQuestions("SQL", out);
        });
    }

    private static QuestionDraft fill(String statement) {
        return new QuestionDraft(QuestionType.FILL_IN_BLANK, statement, null, "x", null);
    }

    private GenerateQuestionBankUseCase.Command command(int newQuestions, BankUpdateMode mode,
                                                       List<QuestionDraft> fromDocument) {
        return new GenerateQuestionBankUseCase.Command(user, material.id(), QuestionFormat.MIXED, newQuestions, mode,
                fromDocument, QuestionType.ALL);
    }

    @Test
    void thirtyQuestionsAreAskedInThreeBatchesOfTen() {
        aiCreatesWhatIsAsked();

        QuestionBankGeneration g = service.generateBank(command(30, BankUpdateMode.REPLACE, List.of()));

        assertThat(g.requested()).isEqualTo(30);
        assertThat(g.created()).isEqualTo(30);
        assertThat(g.view().questions()).hasSize(30);
        verify(assistant, times(3)).practiceQuestions(anyList(), any(QuestionBatch.class), anyList());
    }

    @Test
    void aFailingBatchIsRetriedOnce() {
        AtomicInteger calls = new AtomicInteger();
        when(assistant.practiceQuestions(anyList(), any(QuestionBatch.class), anyList())).thenAnswer(inv -> {
            if (calls.incrementAndGet() == 2) {
                throw new AiUnavailableException("JSON cortado");
            }
            QuestionBatch batch = inv.getArgument(1);
            List<QuestionDraft> out = new ArrayList<>();
            for (int i = 0; i < batch.total(); i++) {
                out.add(fill("Pregunta " + counter.incrementAndGet()));
            }
            return new StudyAssistantPort.PracticeQuestions("SQL", out);
        });

        QuestionBankGeneration g = service.generateBank(command(20, BankUpdateMode.REPLACE, List.of()));

        assertThat(g.created()).isEqualTo(20);
        verify(assistant, times(3)).practiceQuestions(anyList(), any(QuestionBatch.class), anyList());
    }

    @Test
    void aBatchThatKeepsFailingKeepsThePreviousOnes() {
        AtomicInteger calls = new AtomicInteger();
        when(assistant.practiceQuestions(anyList(), any(QuestionBatch.class), anyList())).thenAnswer(inv -> {
            if (calls.incrementAndGet() > 1) {
                throw new AiUnavailableException("caída");
            }
            List<QuestionDraft> out = new ArrayList<>();
            for (int i = 0; i < QuestionBatch.SIZE; i++) {
                out.add(fill("Pregunta " + counter.incrementAndGet()));
            }
            return new StudyAssistantPort.PracticeQuestions("SQL", out);
        });

        QuestionBankGeneration g = service.generateBank(command(30, BankUpdateMode.REPLACE, List.of()));

        assertThat(g.requested()).isEqualTo(30);
        assertThat(g.created()).isEqualTo(10);
        assertThat(g.view().questions()).hasSize(10);
    }

    @Test
    void whenNothingIsCreatedTheBankIsLeftAsItWas() {
        aiCreatesWhatIsAsked();
        service.generateBank(command(5, BankUpdateMode.REPLACE, List.of()));
        when(assistant.practiceQuestions(anyList(), any(QuestionBatch.class), anyList()))
                .thenThrow(new AiUnavailableException("caída"));

        assertThatThrownBy(() -> service.generateBank(command(10, BankUpdateMode.REPLACE, List.of())))
                .isInstanceOf(AiUnavailableException.class);
        assertThat(quiz.getBank(user, material.id()).questions()).hasSize(5);
    }

    @Test
    void addKeepsTheOldOnesAndSkipsRepeatedStatements() {
        aiCreatesWhatIsAsked();
        service.generateBank(command(5, BankUpdateMode.REPLACE, List.of()));
        List<UUID> before = quiz.getBank(user, material.id()).questions().stream().map(Question::id).toList();

        // Una del documento ya estaba (misma pregunta con otras mayúsculas y tildes) y otra es nueva.
        QuestionBankGeneration g = service.generateBank(command(5, BankUpdateMode.ADD,
                List.of(fill("PREGUNTA NUEVA 1"), fill("¿Qué es una clave primaria?"))));

        assertThat(g.created()).isEqualTo(6);
        assertThat(g.view().questions()).hasSize(11);
        assertThat(g.view().questions().stream().map(Question::id)).containsAll(before);
        assertThat(g.view().questions().stream().map(Question::order).distinct()).hasSize(11);
    }

    @Test
    void addingOnlyQuestionsYouAlreadyHaveSavesNothingAndIsNotAnError() {
        aiCreatesWhatIsAsked();
        service.generateBank(command(5, BankUpdateMode.REPLACE, List.of()));

        QuestionBankGeneration g = service.generateBank(command(0, BankUpdateMode.ADD,
                List.of(fill("Pregunta nueva 2"))));

        assertThat(g.requested()).isEqualTo(1);
        assertThat(g.created()).isZero();
        assertThat(g.view().questions()).hasSize(5);
    }

    @Test
    void replaceSwapsTheOldOnes() {
        aiCreatesWhatIsAsked();
        service.generateBank(command(5, BankUpdateMode.REPLACE, List.of()));

        QuestionBankGeneration g = service.generateBank(command(0, BankUpdateMode.REPLACE,
                List.of(fill("Solo esta del apunte"))));

        assertThat(g.view().questions()).singleElement()
                .satisfies(q -> assertThat(q.statement()).isEqualTo("Solo esta del apunte"));
    }

    @Test
    void oldAppsGetNoMultipleAnswerQuestions() {
        when(assistant.practiceQuestions(anyList(), any(QuestionBatch.class), anyList())).thenAnswer(inv ->
                new StudyAssistantPort.PracticeQuestions("SQL", List.of(fill("Hueco"),
                        QuestionDraft.multipleAnswer("¿Cuáles agregan?", List.of("SUM", "JOIN", "AVG"),
                                List.of("SUM", "AVG"), null))));

        QuestionBankGeneration legacy = service.generateBank(GenerateQuestionBankUseCase.Command.legacy(user,
                material.id()));
        assertThat(legacy.view().questions()).extracting(Question::type).containsOnly(QuestionType.FILL_IN_BLANK);

        QuestionBankGeneration current = service.generateBank(command(10, BankUpdateMode.REPLACE, List.of()));
        assertThat(current.view().questions()).extracting(Question::type).contains(QuestionType.MULTIPLE_ANSWER);
        assertThat(quiz.getBank(user, material.id(), QuestionType.LEGACY).questions())
                .extracting(Question::type).doesNotContain(QuestionType.MULTIPLE_ANSWER);
    }

    @Test
    void scanReadsDocumentQuestionsInBatchesAndKeepsTheirStatus() {
        Note note = f.notes.save(Note.create(user, subject.id(), "Examen", "1. ¿Qué es SQL? ...", null, false,
                AcademicFakes.NOW));
        StudyMaterial exam = f.material(user, subject.id(), note.id());
        List<DocumentQuestion> first = new ArrayList<>();
        for (int i = 0; i < QuestionBatch.SIZE; i++) {
            first.add(DocumentQuestion.of(QuestionType.MULTIPLE_CHOICE, "P" + i, List.of("A", "B"), List.of("A"),
                    true, null));
        }
        when(assistant.documentQuestions(any(), eq(0), anyInt()))
                .thenReturn(new StudyAssistantPort.DocumentQuestionPage(13, first));
        when(assistant.documentQuestions(any(), eq(10), anyInt()))
                .thenReturn(new StudyAssistantPort.DocumentQuestionPage(13, List.of(
                        DocumentQuestion.of(QuestionType.FILL_IN_BLANK, "Una clave ____", null, List.of("primaria"),
                                false, null),
                        DocumentQuestion.of(null, "Explica DELETE y TRUNCATE", null, List.of(), false, null),
                        DocumentQuestion.of(QuestionType.MULTIPLE_CHOICE, "Sin respuesta", List.of("A", "B"),
                                List.of(), false, null))));

        DocumentQuestionScan scan = service.scanDocumentQuestions(user, exam.id());

        assertThat(scan.complete()).isTrue();
        assertThat(scan.questions()).hasSize(13);
        assertThat(scan.questions().get(0).status()).isEqualTo(DocumentQuestion.Status.READY);
        assertThat(scan.questions().get(10).status()).isEqualTo(DocumentQuestion.Status.ANSWER_PROPOSED);
        assertThat(scan.questions().get(11).status()).isEqualTo(DocumentQuestion.Status.LONG_ANSWER);
        assertThat(scan.questions().get(12).status()).isEqualTo(DocumentQuestion.Status.NO_ANSWER);
        assertThat(scan.questions().stream().filter(DocumentQuestion::usable)).hasSize(11);
    }

    @Test
    void scanKeepsWhatItReadIfALaterBatchFails() {
        Note note = f.notes.save(Note.create(user, subject.id(), "Examen", "¿Qué es SQL?", null, false,
                AcademicFakes.NOW));
        StudyMaterial exam = f.material(user, subject.id(), note.id());
        List<DocumentQuestion> first = new ArrayList<>();
        for (int i = 0; i < QuestionBatch.SIZE; i++) {
            first.add(DocumentQuestion.of(QuestionType.FILL_IN_BLANK, "P" + i, null, List.of("x"), true, null));
        }
        when(assistant.documentQuestions(any(), eq(0), anyInt()))
                .thenReturn(new StudyAssistantPort.DocumentQuestionPage(25, first));
        when(assistant.documentQuestions(any(), eq(10), anyInt())).thenThrow(new AiUnavailableException("caída"));

        DocumentQuestionScan scan = service.scanDocumentQuestions(user, exam.id());

        assertThat(scan.complete()).isFalse();
        assertThat(scan.questions()).hasSize(10);
        verify(assistant, times(2)).documentQuestions(any(), eq(10), anyInt());
    }

    @Test
    void notesWithoutAnyQuestionSignAreNotSentToTheAi() {
        DocumentQuestionScan scan = service.scanDocumentQuestions(user, material.id());

        assertThat(scan.questions()).isEmpty();
        assertThat(scan.complete()).isTrue();
        verify(assistant, never()).documentQuestions(any(), anyInt(), anyInt());
        assertThat(DocumentQuestion.mayContainQuestions("Ejercicio 3. Normaliza la tabla")).isTrue();
        assertThat(DocumentQuestion.mayContainQuestions("a) Primera\nb) Segunda")).isTrue();
        assertThat(DocumentQuestion.mayContainQuestions("La 1FN pide valores atómicos.")).isFalse();
    }
}
