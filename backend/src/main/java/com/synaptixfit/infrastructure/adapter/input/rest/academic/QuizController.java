package com.synaptixfit.infrastructure.adapter.input.rest.academic;

import com.synaptixfit.application.port.input.academic.AbandonTestSessionUseCase;
import com.synaptixfit.application.port.input.academic.AnswerQuestionUseCase;
import com.synaptixfit.application.port.input.academic.AnswerTestQuestionUseCase;
import com.synaptixfit.application.port.input.academic.CompleteBankPracticeUseCase;
import com.synaptixfit.application.port.input.academic.CompleteTestSessionUseCase;
import com.synaptixfit.application.port.input.academic.GenerateQuestionBankUseCase;
import com.synaptixfit.application.port.input.academic.GetActiveTestSessionUseCase;
import com.synaptixfit.application.port.input.academic.GetMockExamOptionsUseCase;
import com.synaptixfit.application.port.input.academic.GetQuestionBankUseCase;
import com.synaptixfit.application.port.input.academic.GetTestSessionUseCase;
import com.synaptixfit.application.port.input.academic.ListTestSessionsUseCase;
import com.synaptixfit.application.port.input.academic.ScanDocumentQuestionsUseCase;
import com.synaptixfit.application.port.input.academic.StartTestSessionUseCase;
import com.synaptixfit.domain.exception.FieldValidationException;
import com.synaptixfit.domain.model.academic.QuestionType;
import com.synaptixfit.domain.model.academic.TestSessionStatus;
import com.synaptixfit.infrastructure.adapter.input.rest.academic.dto.QuizDtos.AnswerRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.academic.dto.QuizDtos;
import com.synaptixfit.infrastructure.adapter.input.rest.academic.dto.QuizDtos.AnswerResultResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.academic.dto.QuizDtos.CreateQuestionsRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.academic.dto.QuizDtos.DocumentQuestionScanResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.academic.dto.QuizDtos.MockExamOptionsResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.academic.dto.QuizDtos.PracticeCompletionRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.academic.dto.QuizDtos.PracticeResultResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.academic.dto.QuizDtos.QuestionBankResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.academic.dto.QuizDtos.SessionAnswerRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.academic.dto.QuizDtos.SessionAnswerResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.academic.dto.QuizDtos.StartSessionRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.academic.dto.QuizDtos.TestSessionResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.academic.dto.QuizDtos.TestSessionSummaryResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.academic.dto.StudyDtos.QuestionDraftDto;
import com.synaptixfit.infrastructure.adapter.input.rest.support.CurrentUserId;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/**
 * Bancos de preguntas, «Crear preguntas», práctica libre y sesiones de test (práctica y simulacro
 * cronometrado). Cada respuesta lleva solo los tipos de pregunta que la app declara en
 * {@code X-Question-Types} (ADR 0058).
 */
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
    private final GetMockExamOptionsUseCase mockExamOptions;
    private final ScanDocumentQuestionsUseCase scanDocument;

    public QuizController(GetQuestionBankUseCase getBank, GenerateQuestionBankUseCase generateBank,
                          AnswerQuestionUseCase answerQuestion, CompleteBankPracticeUseCase completePractice,
                          StartTestSessionUseCase startSession, GetTestSessionUseCase getSession,
                          GetActiveTestSessionUseCase activeSession, ListTestSessionsUseCase listSessions,
                          AnswerTestQuestionUseCase answerInSession, CompleteTestSessionUseCase completeSession,
                          AbandonTestSessionUseCase abandonSession, GetMockExamOptionsUseCase mockExamOptions,
                          ScanDocumentQuestionsUseCase scanDocument) {
        this.scanDocument = scanDocument;
        this.mockExamOptions = mockExamOptions;
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

    /** Apuntes y archivos de la asignatura que pueden entrar en un simulacro, con sus límites. */
    @GetMapping("/subjects/{subjectId}/mock-exam-options")
    public MockExamOptionsResponse mockExamOptions(@CurrentUserId UUID userId, @PathVariable UUID subjectId) {
        return MockExamOptionsResponse.from(mockExamOptions.getMockExamOptions(userId, subjectId));
    }

    @GetMapping("/study-materials/{materialId}/question-bank")
    public QuestionBankResponse bank(@CurrentUserId UUID userId, @PathVariable UUID materialId,
                                     @RequestHeader(name = QuestionTypesHeader.NAME, required = false) String types) {
        return QuestionBankResponse.from(getBank.getBank(userId, materialId, QuestionTypesHeader.parse(types)));
    }

    /**
     * «Crear preguntas» (ADR 0058): las del documento ya revisadas y las nuevas, que la IA crea por tandas.
     * Sin cuerpo (apps anteriores): 10 mezcladas que sustituyen a las de antes.
     */
    @PostMapping("/study-materials/{materialId}/question-bank")
    @ResponseStatus(HttpStatus.CREATED)
    public QuestionBankResponse generate(@CurrentUserId UUID userId, @PathVariable UUID materialId,
                                         @RequestHeader(name = QuestionTypesHeader.NAME, required = false) String types,
                                         @Valid @RequestBody(required = false) CreateQuestionsRequest r) {
        Set<QuestionType> supported = QuestionTypesHeader.parse(types);
        GenerateQuestionBankUseCase.Command command = r == null
                ? GenerateQuestionBankUseCase.Command.legacy(userId, materialId)
                : new GenerateQuestionBankUseCase.Command(userId, materialId, r.format(),
                r.newQuestions() == null ? 0 : r.newQuestions(), r.mode(),
                r.documentQuestions() == null ? List.of()
                        : r.documentQuestions().stream().map(QuestionDraftDto::toDomain).toList(), supported);
        return QuestionBankResponse.from(generateBank.generateBank(command));
    }

    /** Busca con IA las preguntas que ya trae escritas el documento; no guarda nada (ADR 0058). */
    @PostMapping("/study-materials/{materialId}/document-questions")
    public DocumentQuestionScanResponse documentQuestions(@CurrentUserId UUID userId, @PathVariable UUID materialId,
                                                          @RequestHeader(name = QuestionTypesHeader.NAME,
                                                                  required = false) String types) {
        return DocumentQuestionScanResponse.from(scanDocument.scanDocumentQuestions(userId, materialId),
                QuestionTypesHeader.parse(types));
    }

    @PostMapping("/questions/{questionId}/attempts")
    public AnswerResultResponse attempt(@CurrentUserId UUID userId, @PathVariable UUID questionId,
                                        @Valid @RequestBody AnswerRequest r) {
        return AnswerResultResponse.from(answerQuestion.answerQuestion(userId, questionId,
                required(QuizDtos.given(r.answer(), r.answers()))));
    }

    @PostMapping("/question-banks/{bankId}/practice-completions")
    public PracticeResultResponse completePractice(@CurrentUserId UUID userId, @PathVariable UUID bankId,
                                                   @RequestHeader(name = QuestionTypesHeader.NAME,
                                                           required = false) String types,
                                                   @Valid @RequestBody PracticeCompletionRequest r) {
        return PracticeResultResponse.from(completePractice.completePractice(userId, bankId, r.merged(),
                QuestionTypesHeader.parse(types)));
    }

    @PostMapping("/test-sessions")
    @ResponseStatus(HttpStatus.CREATED)
    public TestSessionResponse start(@CurrentUserId UUID userId,
                                     @RequestHeader(name = QuestionTypesHeader.NAME, required = false) String types,
                                     @Valid @RequestBody StartSessionRequest r) {
        Set<QuestionType> supported = QuestionTypesHeader.parse(types);
        return TestSessionResponse.from(startSession.startSession(new StartTestSessionUseCase.Command(userId,
                r.materialIds(), r.questionCount(), supported)), supported);
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
    public ResponseEntity<TestSessionResponse> active(@CurrentUserId UUID userId, @RequestParam UUID materialId,
                                                      @RequestHeader(name = QuestionTypesHeader.NAME,
                                                              required = false) String types) {
        return activeSession.findActiveSession(userId, materialId)
                .map(v -> ResponseEntity.ok(TestSessionResponse.from(v, QuestionTypesHeader.parse(types))))
                .orElseGet(() -> ResponseEntity.noContent().build());
    }

    @GetMapping("/test-sessions/{sessionId}")
    public TestSessionResponse get(@CurrentUserId UUID userId, @PathVariable UUID sessionId,
                                   @RequestHeader(name = QuestionTypesHeader.NAME, required = false) String types) {
        return TestSessionResponse.from(getSession.getSession(userId, sessionId), QuestionTypesHeader.parse(types));
    }

    @PostMapping("/test-sessions/{sessionId}/answers")
    public SessionAnswerResponse answer(@CurrentUserId UUID userId, @PathVariable UUID sessionId,
                                        @RequestHeader(name = QuestionTypesHeader.NAME, required = false) String types,
                                        @Valid @RequestBody SessionAnswerRequest r) {
        return SessionAnswerResponse.from(answerInSession.answer(new AnswerTestQuestionUseCase.Command(userId,
                sessionId, r.questionId(), required(QuizDtos.given(r.answer(), r.answers())), r.nextIndex())),
                QuestionTypesHeader.parse(types));
    }

    @PostMapping("/test-sessions/{sessionId}/complete")
    public TestSessionResponse complete(@CurrentUserId UUID userId, @PathVariable UUID sessionId,
                                        @RequestHeader(name = QuestionTypesHeader.NAME, required = false) String types) {
        return TestSessionResponse.from(completeSession.completeSession(userId, sessionId),
                QuestionTypesHeader.parse(types));
    }

    @PostMapping("/test-sessions/{sessionId}/abandon")
    public TestSessionResponse abandon(@CurrentUserId UUID userId, @PathVariable UUID sessionId,
                                       @RequestHeader(name = QuestionTypesHeader.NAME, required = false) String types) {
        return TestSessionResponse.from(abandonSession.abandonSession(userId, sessionId),
                QuestionTypesHeader.parse(types));
    }

    /** {@code answer} o {@code answers}: una de las dos es obligatoria. */
    private static String required(String given) {
        if (given == null) {
            throw new FieldValidationException("answer", "REQUIRED", "answer or answers is required");
        }
        return given;
    }
}
