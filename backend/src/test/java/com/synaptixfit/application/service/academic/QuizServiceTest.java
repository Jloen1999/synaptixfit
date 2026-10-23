package com.synaptixfit.application.service.academic;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import com.synaptixfit.application.port.input.academic.AnswerTestQuestionUseCase;
import com.synaptixfit.application.port.input.academic.StartTestSessionUseCase;
import com.synaptixfit.domain.exception.academic.QuestionBankNotFoundException;
import com.synaptixfit.domain.exception.academic.QuestionNotFoundException;
import com.synaptixfit.domain.exception.academic.TestSessionNotFoundException;
import com.synaptixfit.domain.exception.academic.TestSessionNotInProgressException;
import com.synaptixfit.domain.model.academic.AiDocumentType;
import com.synaptixfit.domain.model.academic.PracticeResult;
import com.synaptixfit.domain.model.academic.Question;
import com.synaptixfit.domain.model.academic.QuestionBank;
import com.synaptixfit.domain.model.academic.QuestionBankView;
import com.synaptixfit.domain.model.academic.QuestionDraft;
import com.synaptixfit.domain.model.academic.QuestionType;
import com.synaptixfit.domain.model.academic.StudyMaterial;
import com.synaptixfit.domain.model.academic.Subject;
import com.synaptixfit.domain.model.academic.TestSessionStatus;
import com.synaptixfit.domain.model.academic.TestSessionView;
import com.synaptixfit.domain.port.output.academic.StudyAssistantPort;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Random;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class QuizServiceTest {

    private final AcademicFakes f = new AcademicFakes();
    private final StudyAssistantPort assistant = mock(StudyAssistantPort.class);
    private final QuizService service = new QuizService(f.banks, f.attempts, f.sessions, f.materials, f.subjects,
            f.notes, f.files, f.aiDocuments, f.codec, assistant, f.storage, f.award, f.events::add, AcademicFakes.CLOCK,
            new Random(7));
    private final UUID user = UUID.randomUUID();
    private final UUID stranger = UUID.randomUUID();
    private Subject subject;
    private StudyMaterial material;
    private QuestionBank bank;
    private List<Question> questions;

    @BeforeEach
    void setUp() {
        subject = f.subject(user, "Historia");
        material = f.material(user, subject.id(), f.note(user, subject.id(), "Edad Media").id());
        bank = f.banks.save(QuestionBank.create(material.id(), user, AcademicFakes.NOW));
        questions = new ArrayList<>();
        for (int i = 0; i < 5; i++) {
            questions.add(Question.from(new QuestionDraft(QuestionType.FILL_IN_BLANK, "Pregunta " + i, null,
                    "Respuesta " + i, null), bank.id(), i));
        }
        f.banks.replaceQuestions(bank.id(), questions);
    }

    @Test
    void answeringIsGradedTolerantlyAndRecorded() {
        Question q = questions.getFirst();
        assertThat(service.answerQuestion(user, q.id(), "  respuesta 0. ").correct()).isTrue();
        assertThat(service.answerQuestion(user, q.id(), "otra").correct()).isFalse();
        assertThat(f.attemptStore).hasSize(2);
        assertThatThrownBy(() -> service.answerQuestion(stranger, q.id(), "x"))
                .isInstanceOf(QuestionNotFoundException.class);

        QuestionBankView view = service.getBank(user, material.id());
        assertThat(view.attemptedQuestions()).isEqualTo(1);
        assertThat(view.correctQuestions()).isEqualTo(1);
    }

    @Test
    void sessionPrioritizesFailedQuestionsAndAwardsXpOnce() {
        Question failed = questions.get(3);
        service.answerQuestion(user, failed.id(), "mal");

        TestSessionView started = service.startSession(new StartTestSessionUseCase.Command(user,
                List.of(material.id()), 1));
        assertThat(started.session().questionIds()).containsExactly(failed.id());

        TestSessionView full = service.startSession(new StartTestSessionUseCase.Command(user, List.of(material.id()),
                null));
        assertThat(full.questions()).hasSize(5);
        UUID sessionId = full.session().id();
        for (Question q : full.questions()) {
            String answer = q.id().equals(failed.id()) ? "mal" : q.correctAnswer();
            service.answer(new AnswerTestQuestionUseCase.Command(user, sessionId, q.id(), answer, null));
        }
        TestSessionView done = service.completeSession(user, sessionId);
        assertThat(done.session().status()).isEqualTo(TestSessionStatus.COMPLETED);
        assertThat(done.session().score()).isEqualTo(4);
        // 4/5 = 80 %: 20 + 10 de bonus.
        assertThat(done.xpAwarded()).isEqualTo(30);
        assertThat(f.xp.get(user)).isEqualTo(30);

        assertThatThrownBy(() -> service.completeSession(user, sessionId))
                .isInstanceOf(TestSessionNotInProgressException.class);
        assertThatThrownBy(() -> service.getSession(stranger, sessionId))
                .isInstanceOf(TestSessionNotFoundException.class);
    }

    @Test
    void incompleteSessionGivesNoXpAndAbandonedSessionsRejectAnswers() {
        TestSessionView started = service.startSession(new StartTestSessionUseCase.Command(user,
                List.of(material.id()), 3));
        UUID id = started.session().id();
        Question first = started.questions().getFirst();
        service.answer(new AnswerTestQuestionUseCase.Command(user, id, first.id(), first.correctAnswer(), 1));
        assertThat(service.findActiveSession(user, material.id())).isPresent();

        TestSessionView done = service.completeSession(user, id);
        assertThat(done.xpAwarded()).isZero();
        assertThat(f.xp).isEmpty();

        UUID other = service.startSession(new StartTestSessionUseCase.Command(user, List.of(material.id()), 2))
                .session().id();
        service.abandonSession(user, other);
        assertThatThrownBy(() -> service.answer(new AnswerTestQuestionUseCase.Command(user, other,
                first.id(), "x", null))).isInstanceOf(TestSessionNotInProgressException.class);
        UUID open = service.startSession(new StartTestSessionUseCase.Command(user, List.of(material.id()), 2))
                .session().id();
        assertThatThrownBy(() -> service.answer(new AnswerTestQuestionUseCase.Command(user, open, UUID.randomUUID(),
                "x", null))).isInstanceOf(QuestionNotFoundException.class);
    }

    @Test
    void bankPracticeGivesXpOncePerBankWhenFullyAnswered() {
        Map<UUID, String> all = new java.util.HashMap<>();
        questions.forEach(q -> all.put(q.id(), q.correctAnswer()));

        PracticeResult partial = service.completePractice(user, bank.id(), Map.of(questions.getFirst().id(), "x"));
        assertThat(partial.xpAwarded()).isZero();

        PracticeResult full = service.completePractice(user, bank.id(), all);
        assertThat(full.correct()).isEqualTo(5);
        assertThat(full.xpAwarded()).isEqualTo(30);
        assertThat(service.completePractice(user, bank.id(), all).xpAwarded()).isZero();
        assertThat(f.xp.get(user)).isEqualTo(30);
        assertThatThrownBy(() -> service.completePractice(stranger, bank.id(), all))
                .isInstanceOf(QuestionBankNotFoundException.class);
    }

    @Test
    void combinedSessionMixesMaterialsOfTheUser() {
        StudyMaterial second = f.material(user, subject.id(), f.note(user, subject.id(), "Edad Moderna").id());
        QuestionBank bank2 = f.banks.save(QuestionBank.create(second.id(), user, AcademicFakes.NOW));
        f.banks.replaceQuestions(bank2.id(), List.of(Question.from(new QuestionDraft(QuestionType.FILL_IN_BLANK,
                "¿Año?", null, "1492", null), bank2.id(), 0)));

        TestSessionView combined = service.startSession(new StartTestSessionUseCase.Command(user,
                List.of(material.id(), second.id()), null));
        // 20 / 2 = 10 por material como máximo: 5 + 1 disponibles.
        assertThat(combined.questions()).hasSize(6);
        assertThat(combined.session().materialId()).isEqualTo(material.id());

        StudyMaterial foreign = f.material(stranger, f.subject(stranger, "Ajena").id(), UUID.randomUUID());
        assertThatThrownBy(() -> service.startSession(new StartTestSessionUseCase.Command(user,
                List.of(material.id(), foreign.id()), null))).hasFieldOrPropertyWithValue("code",
                "STUDY_MATERIAL_NOT_FOUND");
    }

    @Test
    void generateBankReplacesQuestionsAndMarksPracticeDocument() {
        when(assistant.practiceQuestions(org.mockito.ArgumentMatchers.anyList()))
                .thenReturn(new StudyAssistantPort.PracticeQuestions("Edad Media", List.of(
                        new QuestionDraft(QuestionType.MULTIPLE_CHOICE, "¿Capital?", List.of("Toledo", "Roma"),
                                "Toledo", "Era la capital"))));

        QuestionBankView view = service.generateBank(user, material.id());

        assertThat(view.bank().id()).isEqualTo(bank.id());
        assertThat(view.questions()).singleElement().satisfies(q -> assertThat(q.options()).hasSize(2));
        assertThat(f.docStore.values()).singleElement()
                .satisfies(d -> assertThat(d.type()).isEqualTo(AiDocumentType.PRACTICE));
        assertThatThrownBy(() -> service.generateBank(stranger, material.id()))
                .hasFieldOrPropertyWithValue("code", "STUDY_MATERIAL_NOT_FOUND");
    }
}
