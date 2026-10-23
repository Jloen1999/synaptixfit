package com.synaptixfit.infrastructure.adapter.input.rest.academic;

import com.synaptixfit.application.port.input.academic.AbandonTestSessionUseCase;
import com.synaptixfit.application.port.input.academic.AnswerQuestionUseCase;
import com.synaptixfit.application.port.input.academic.AnswerTestQuestionUseCase;
import com.synaptixfit.application.port.input.academic.CompleteBankPracticeUseCase;
import com.synaptixfit.application.port.input.academic.CompleteTestSessionUseCase;
import com.synaptixfit.application.port.input.academic.GenerateQuestionBankUseCase;
import com.synaptixfit.application.port.input.academic.GetActiveTestSessionUseCase;
import com.synaptixfit.application.port.input.academic.GetQuestionBankUseCase;
import com.synaptixfit.application.port.input.academic.GetTestSessionUseCase;
import com.synaptixfit.application.port.input.academic.ListTestSessionsUseCase;
import com.synaptixfit.application.port.input.academic.StartTestSessionUseCase;
import com.synaptixfit.domain.model.academic.TestSessionStatus;
import com.synaptixfit.infrastructure.adapter.input.rest.academic.dto.QuizDtos.AnswerRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.academic.dto.QuizDtos.AnswerResultResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.academic.dto.QuizDtos.PracticeCompletionRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.academic.dto.QuizDtos.PracticeResultResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.academic.dto.QuizDtos.QuestionBankResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.academic.dto.QuizDtos.SessionAnswerRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.academic.dto.QuizDtos.SessionAnswerResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.academic.dto.QuizDtos.StartSessionRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.academic.dto.QuizDtos.TestSessionResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.academic.dto.QuizDtos.TestSessionSummaryResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.support.CurrentUserId;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/** Bancos de preguntas, práctica libre y sesiones de test (práctica y simulacro cronometrado). */
@Tag(name = "Academic - Quizzes")
@RestController
@RequestMapping("/api/v1")
public class QuizController {

    private final GetQuestionBankUseCase getBank;
    private final GenerateQuestionBankUseCase generateBank;
    private final AnswerQuestionUseCase answerQuestion;
    private final CompleteBankPracticeUseCase completePractice;
    private final StartTestSessionUseCase startSession;
    private final GetTestSessionUseCase getSession;
    private final GetActiveTestSessionUseCase activeSession;
    private final ListTestSessionsUseCase listSessions;
    private final AnswerTestQuestionUseCase answerInSession;
    private final CompleteTestSessionUseCase completeSession;
    private final AbandonTestSessionUseCase abandonSession;

    public QuizController(GetQuestionBankUseCase getBank, GenerateQuestionBankUseCase generateBank,
                          AnswerQuestionUseCase answerQuestion, CompleteBankPracticeUseCase completePractice,
                          StartTestSessionUseCase startSession, GetTestSessionUseCase getSession,
                          GetActiveTestSessionUseCase activeSession, ListTestSessionsUseCase listSessions,
                          AnswerTestQuestionUseCase answerInSession, CompleteTestSessionUseCase completeSession,
                          AbandonTestSessionUseCase abandonSession) {
        this.getBank = getBank;
        this.generateBank = generateBank;
        this.answerQuestion = answerQuestion;
        this.completePractice = completePractice;
        this.startSession = startSession;
        this.getSession = getSession;
        this.activeSession = activeSession;
        this.listSessions = listSessions;
        this.answerInSession = answerInSession;
        this.completeSession = completeSession;
        this.abandonSession = abandonSession;
    }

    @GetMapping("/study-materials/{materialId}/question-bank")
    public QuestionBankResponse bank(@CurrentUserId UUID userId, @PathVariable UUID materialId) {
        return QuestionBankResponse.from(getBank.getBank(userId, materialId));
    }

    @PostMapping("/study-materials/{materialId}/question-bank")
    @ResponseStatus(HttpStatus.CREATED)
    public QuestionBankResponse generate(@CurrentUserId UUID userId, @PathVariable UUID materialId) {
        return QuestionBankResponse.from(generateBank.generateBank(userId, materialId));
    }

    @PostMapping("/questions/{questionId}/attempts")
    public AnswerResultResponse attempt(@CurrentUserId UUID userId, @PathVariable UUID questionId,
                                        @Valid @RequestBody AnswerRequest r) {
        return AnswerResultResponse.from(answerQuestion.answerQuestion(userId, questionId, r.answer()));
    }

    @PostMapping("/question-banks/{bankId}/practice-completions")
    public PracticeResultResponse completePractice(@CurrentUserId UUID userId, @PathVariable UUID bankId,
                                                   @Valid @RequestBody PracticeCompletionRequest r) {
        return PracticeResultResponse.from(completePractice.completePractice(userId, bankId, r.answers()));
    }

    @PostMapping("/test-sessions")
    @ResponseStatus(HttpStatus.CREATED)
    public TestSessionResponse start(@CurrentUserId UUID userId, @Valid @RequestBody StartSessionRequest r) {
        return TestSessionResponse.from(startSession.startSession(new StartTestSessionUseCase.Command(userId,
                r.materialIds(), r.questionCount())));
    }

    @GetMapping("/test-sessions")
    public List<TestSessionSummaryResponse> list(@CurrentUserId UUID userId,
                                                 @RequestParam(required = false) UUID materialId,
                                                 @RequestParam(required = false) TestSessionStatus status) {
        return listSessions.listSessions(userId, materialId, status).stream()
                .map(TestSessionSummaryResponse::from).toList();
    }

    /** 200 con la sesión en curso del material o 204 si no hay ninguna. */
    @GetMapping("/test-sessions/active")
    public ResponseEntity<TestSessionResponse> active(@CurrentUserId UUID userId, @RequestParam UUID materialId) {
        return activeSession.findActiveSession(userId, materialId)
                .map(v -> ResponseEntity.ok(TestSessionResponse.from(v)))
                .orElseGet(() -> ResponseEntity.noContent().build());
    }

    @GetMapping("/test-sessions/{sessionId}")
    public TestSessionResponse get(@CurrentUserId UUID userId, @PathVariable UUID sessionId) {
        return TestSessionResponse.from(getSession.getSession(userId, sessionId));
    }

    @PostMapping("/test-sessions/{sessionId}/answers")
    public SessionAnswerResponse answer(@CurrentUserId UUID userId, @PathVariable UUID sessionId,
                                        @Valid @RequestBody SessionAnswerRequest r) {
        return SessionAnswerResponse.from(answerInSession.answer(new AnswerTestQuestionUseCase.Command(userId,
                sessionId, r.questionId(), r.answer(), r.nextIndex())));
    }

    @PostMapping("/test-sessions/{sessionId}/complete")
    public TestSessionResponse complete(@CurrentUserId UUID userId, @PathVariable UUID sessionId) {
        return TestSessionResponse.from(completeSession.completeSession(userId, sessionId));
    }

    @PostMapping("/test-sessions/{sessionId}/abandon")
    public TestSessionResponse abandon(@CurrentUserId UUID userId, @PathVariable UUID sessionId) {
        return TestSessionResponse.from(abandonSession.abandonSession(userId, sessionId));
    }
}
