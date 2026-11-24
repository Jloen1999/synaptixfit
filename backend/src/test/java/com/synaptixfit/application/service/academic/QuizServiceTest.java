package com.synaptixfit.application.service.academic;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import com.synaptixfit.application.port.input.academic.AnswerTestQuestionUseCase;
import com.synaptixfit.application.port.input.academic.GenerateQuestionBankUseCase;
import com.synaptixfit.application.port.input.academic.StartTestSessionUseCase;
import com.synaptixfit.domain.exception.academic.QuestionAlreadyAnsweredException;
import com.synaptixfit.domain.exception.academic.QuestionBankNotFoundException;
import com.synaptixfit.domain.exception.academic.QuestionNotFoundException;
import com.synaptixfit.domain.exception.academic.TestSessionNotFoundException;
import com.synaptixfit.domain.exception.academic.TestSessionNotInProgressException;
import com.synaptixfit.domain.model.academic.AiDocumentType;
import com.synaptixfit.domain.model.academic.AnswerResult;
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

        // «Acertada» es la del último intento (ADR 0063); con el reloj fijo los dos intentos tienen la misma hora
        // y gana el de nota más baja: la mala.
        QuestionBankView view = service.getBank(user, material.id());
        assertThat(view.attemptedQuestions()).isEqualTo(1);
        assertThat(view.correctQuestions()).isZero();
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
        when(assistant.practiceQuestions(org.mockito.ArgumentMatchers.anyList(), org.mockito.ArgumentMatchers.any(),
                org.mockito.ArgumentMatchers.anyList()))
                .thenReturn(new StudyAssistantPort.PracticeQuestions("Edad Media", List.of(
                        new QuestionDraft(QuestionType.MULTIPLE_CHOICE, "¿Capital?", List.of("Toledo", "Roma"),
                                "Toledo", "Era la capital"))));

        QuestionCreationService creation = new QuestionCreationService(f.banks, f.materials, f.subjects, f.notes,
                f.files, f.aiDocuments, f.codec, assistant, f.storage, service, service, AcademicFakes.CLOCK);
        QuestionBankView view = creation.generateBank(
                GenerateQuestionBankUseCase.Command.legacy(user, material.id())).view();

        assertThat(view.bank().id()).isEqualTo(bank.id());
        assertThat(view.questions()).singleElement().satisfies(q -> assertThat(q.options()).hasSize(2));
        assertThat(f.docStore.values()).singleElement()
                .satisfies(d -> assertThat(d.type()).isEqualTo(AiDocumentType.PRACTICE));
        assertThatThrownBy(() -> creation.generateBank(GenerateQuestionBankUseCase.Command.legacy(stranger,
                material.id())))
                .hasFieldOrPropertyWithValue("code", "STUDY_MATERIAL_NOT_FOUND");
    }

    @Test
    void dontKnowShowsTheAnswerAndTheQuestionComesBackFirst() {
        Question unknown = questions.get(2);
        Question wrong = questions.get(4);
        service.answerQuestion(user, wrong.id(), "mal");
        AnswerResult result = service.dontKnow(user, unknown.id());
        assertThat(result.dontKnow()).isTrue();
        assertThat(result.correct()).isFalse();
        assertThat(result.correctAnswers()).containsExactly("Respuesta 2");
        assertThat(f.attemptStore).anySatisfy(a -> {
            assertThat(a.questionId()).isEqualTo(unknown.id());
            assertThat(a.dontKnow()).isTrue();
        });
        assertThatThrownBy(() -> service.dontKnow(stranger, unknown.id()))
                .isInstanceOf(QuestionNotFoundException.class);

        // En el banco (práctica libre y tarjetas) también salen primero: «No lo sé», fallada y luego las nuevas.
        assertThat(service.getBank(user, material.id()).questions()).extracting(Question::id)
                .startsWith(unknown.id(), wrong.id(), questions.get(0).id());

        // «No lo sé» vuelve antes que la fallada, y esta antes que las nuevas.
        TestSessionView two = service.startSession(new StartTestSessionUseCase.Command(user,
                List.of(material.id()), 2));
        assertThat(two.session().questionIds()).containsExactlyInAnyOrder(unknown.id(), wrong.id());
        TestSessionView one = service.startSession(new StartTestSessionUseCase.Command(user,
                List.of(material.id()), 1));
        assertThat(one.session().questionIds()).containsExactly(unknown.id());
    }

    @Test
    void dontKnowInASessionCountsAsAnsweredAndFailed() {
        TestSessionView started = service.startSession(new StartTestSessionUseCase.Command(user,
                List.of(material.id()), null));
        UUID id = started.session().id();
        List<Question> qs = started.questions();
        var answer = service.answer(new AnswerTestQuestionUseCase.Command(user, id, qs.getFirst().id(), null, null,
                true));
        assertThat(answer.result().dontKnow()).isTrue();
        assertThat(answer.result().correctAnswers()).isNotEmpty();
        for (Question q : qs.subList(1, qs.size())) {
            service.answer(new AnswerTestQuestionUseCase.Command(user, id, q.id(), q.correctAnswer(), null));
        }
        TestSessionView done = service.completeSession(user, id);
        assertThat(done.session().counted()).isTrue();
        assertThat(done.session().score()).isEqualTo(4);
        // Todas respondidas por la persona (un «No lo sé» suyo cuenta) y 4/5 = 80 %: 20 + 10 de bonus.
        assertThat(done.xpAwarded()).isEqualTo(30);
    }

    @Test
    void mockExamSubmittedWithNoAnswersDoesNotCount() {
        TestSessionView started = service.startSession(new StartTestSessionUseCase.Command(user,
                List.of(material.id()), null));
        UUID id = started.session().id();
        assertThat(started.session().countsIfSubmitted()).isFalse();

        TestSessionView done = service.completeSession(user, id);

        assertThat(done.session().counted()).isFalse();
        assertThat(done.session().status()).isEqualTo(TestSessionStatus.ABANDONED);
        assertThat(done.xpAwarded()).isZero();
        assertThat(f.xp).isEmpty();
        assertThat(f.events).isEmpty();
        assertThat(f.attemptStore).isEmpty();
        // No sale en el historial, pero sigue existiendo (una app anterior puede abrir sus resultados).
        assertThat(service.listSessions(user, null, null)).isEmpty();
        assertThat(service.getSession(user, id).session().status()).isEqualTo(TestSessionStatus.ABANDONED);
        // Entregarla otra vez: 409, como cualquier sesión cerrada.
        assertThatThrownBy(() -> service.completeSession(user, id))
                .isInstanceOf(TestSessionNotInProgressException.class);
    }

    @Test
    void aCorrectedQuestionCannotBeAnsweredAgain() {
        TestSessionView started = service.startSession(new StartTestSessionUseCase.Command(user,
                List.of(material.id()), null));
        UUID id = started.session().id();
        Question first = started.questions().getFirst();
        Question second = started.questions().get(1);
        service.answer(new AnswerTestQuestionUseCase.Command(user, id, first.id(), null, null, true));
        service.answer(new AnswerTestQuestionUseCase.Command(user, id, second.id(), "mal", null));
        int attemptsBefore = f.attemptStore.size();

        // Con la solución a la vista, mandar la buena no cambia nada.
        assertThatThrownBy(() -> service.answer(new AnswerTestQuestionUseCase.Command(user, id, first.id(),
                first.correctAnswer(), null))).isInstanceOf(QuestionAlreadyAnsweredException.class)
                .hasFieldOrPropertyWithValue("code", "QUIZ_QUESTION_ALREADY_ANSWERED");
        assertThatThrownBy(() -> service.answer(new AnswerTestQuestionUseCase.Command(user, id, second.id(),
                second.correctAnswer(), null))).isInstanceOf(QuestionAlreadyAnsweredException.class);
        assertThatThrownBy(() -> service.answer(new AnswerTestQuestionUseCase.Command(user, id, second.id(),
                null, null, true))).isInstanceOf(QuestionAlreadyAnsweredException.class);
        assertThat(f.attemptStore).hasSize(attemptsBefore);
        assertThat(service.getSession(user, id).session().score()).isZero();
    }

    @Test
    void closingFreePracticeUsesTheCheckedAttemptNotTheFinalAnswer() {
        Map<UUID, String> answers = new java.util.HashMap<>();
        questions.forEach(q -> answers.put(q.id(), q.correctAnswer()));
        // La primera se comprobó mal; al cerrar llega la buena (ya vista en la corrección): no cuenta.
        service.answerQuestion(user, questions.getFirst().id(), "mal");
        PracticeResult result = service.completePractice(user, bank.id(), answers);
        assertThat(result.correct()).isEqualTo(4);
    }

    @Test
    void unansweredQuestionsOfASubmittedMockExamCountAsDontKnow() {
        TestSessionView started = service.startSession(new StartTestSessionUseCase.Command(user,
                List.of(material.id()), null));
        UUID id = started.session().id();
        Question first = started.questions().getFirst();
        service.answer(new AnswerTestQuestionUseCase.Command(user, id, first.id(), first.correctAnswer(), null));

        TestSessionView done = service.completeSession(user, id);

        assertThat(done.session().counted()).isTrue();
        assertThat(done.session().unansweredAtSubmit()).hasSize(4);
        assertThat(done.session().answeredCount()).isEqualTo(1);
        assertThat(done.xpAwarded()).isZero();
        assertThat(f.attemptStore.stream().filter(a -> a.dontKnow()).count()).isEqualTo(4);
        assertThat(f.events).hasSize(1);
    }

    @Test
    void bankPracticeCountsDontKnowAsAnsweredButNeverCorrect() {
        Map<UUID, String> answers = new java.util.HashMap<>();
        questions.subList(1, questions.size()).forEach(q -> answers.put(q.id(), q.correctAnswer()));
        // Aunque llegue también una respuesta, la del «No lo sé» no cuenta como acierto.
        answers.put(questions.getFirst().id(), questions.getFirst().correctAnswer());
        PracticeResult result = service.completePractice(user, bank.id(), answers,
                java.util.Set.of(questions.getFirst().id()), QuestionType.ALL);
        assertThat(result.correct()).isEqualTo(4);
        assertThat(result.xpAwarded()).isEqualTo(30);
    }
}
