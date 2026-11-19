package com.synaptixfit.infrastructure.adapter.input.rest.academic.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import com.synaptixfit.domain.model.academic.AnswerResult;
import com.synaptixfit.domain.model.academic.BankUpdateMode;
import com.synaptixfit.domain.model.academic.DocumentQuestion;
import com.synaptixfit.domain.model.academic.DocumentQuestionScan;
import com.synaptixfit.domain.model.academic.MockExamOptions;
import com.synaptixfit.domain.model.academic.PracticeResult;
import com.synaptixfit.domain.model.academic.Question;
import com.synaptixfit.domain.model.academic.QuestionBankGeneration;
import com.synaptixfit.domain.model.academic.QuestionBankView;
import com.synaptixfit.domain.model.academic.QuestionFormat;
import com.synaptixfit.domain.model.academic.QuestionType;
import com.synaptixfit.domain.model.academic.SessionAnswer;
import com.synaptixfit.domain.model.academic.StudySourceType;
import com.synaptixfit.domain.model.academic.TestSession;
import com.synaptixfit.domain.model.academic.TestSessionStatus;
import com.synaptixfit.domain.model.academic.TestSessionView;
import com.synaptixfit.infrastructure.adapter.input.rest.academic.dto.StudyDtos.QuestionDraftDto;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.time.Instant;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

/** DTOs de bancos de preguntas, práctica y sesiones de test. */
public final class QuizDtos {

    private QuizDtos() {
    }

    /**
     * Respuesta dada: {@code answers} (lista) en «Varias correctas» o {@code answer} en el resto. Se unen como
     * las guarda el dominio ({@link Question#joinAnswers}); nula si no llega ninguna.
     */
    public static String given(String answer, List<String> answers) {
        return answers != null && !answers.isEmpty() ? Question.joinAnswers(answers) : answer;
    }

    /**
     * Pregunta con su solución (banco completo: tarjetas y práctica libre). {@code correctAnswers} lleva todas
     * las correctas («Varias correctas», ADR 0058); {@code correctAnswer}, la única o todas unidas con « · ».
     */
    public record QuestionResponse(UUID id, QuestionType type, String statement, List<String> options, int order,
                                   String correctAnswer, String explanation, List<String> correctAnswers) {

        public static QuestionResponse from(Question q) {
            return new QuestionResponse(q.id(), q.type(), q.statement(), q.options(), q.order(),
                    String.join(" · ", q.correctAnswers()), q.explanation(), q.correctAnswers());
        }
    }

    /**
     * Banco con sus preguntas. Al crear preguntas ({@code POST}) lleva además cuántas se pidieron y cuántas
     * se guardaron (pueden ser menos si falló una tanda o ya las tenías); en la lectura van nulos.
     */
    public record QuestionBankResponse(UUID id, UUID materialId, Instant generatedAt, boolean xpAwarded,
                                       int questionCount, int attemptedQuestions, int correctQuestions,
                                       List<QuestionResponse> questions, Integer requestedQuestions,
                                       Integer createdQuestions) {

        public static QuestionBankResponse from(QuestionBankView v) {
            return of(v, null, null);
        }

        public static QuestionBankResponse from(QuestionBankGeneration g) {
            return of(g.view(), g.requested(), g.created());
        }

        private static QuestionBankResponse of(QuestionBankView v, Integer requested, Integer created) {
            return new QuestionBankResponse(v.bank().id(), v.bank().materialId(), v.bank().generatedAt(),
                    v.bank().xpAwarded(), v.questions().size(), v.attemptedQuestions(), v.correctQuestions(),
                    v.questions().stream().map(QuestionResponse::from).toList(), requested, created);
        }
    }

    /**
     * «Crear preguntas» (ADR 0058). Sin cuerpo se hace lo de antes: 10 mezcladas que sustituyen a las que
     * hubiera. {@code documentQuestions} son las del documento que la persona revisó y quiso usar.
     */
    public record CreateQuestionsRequest(QuestionFormat format,
                                         @Min(0) @Max(30) Integer newQuestions,
                                         BankUpdateMode mode,
                                         @Size(max = 40) List<@Valid @NotNull QuestionDraftDto> documentQuestions) {
    }

    /** Pregunta que ya traía el documento; {@code type} nulo si es de respuesta larga. */
    public record DocumentQuestionResponse(QuestionType type, String statement, List<String> options,
                                           List<String> correctAnswers, String explanation,
                                           DocumentQuestion.Status status) {

        public static DocumentQuestionResponse from(DocumentQuestion q) {
            return new DocumentQuestionResponse(q.type(), q.statement(), q.options(), q.answers(), q.explanation(),
                    q.status());
        }
    }

    /** Preguntas del documento; {@code complete} falso si no se pudieron leer todas. */
    public record DocumentQuestionScanResponse(List<DocumentQuestionResponse> questions, boolean complete) {

        public static DocumentQuestionScanResponse from(DocumentQuestionScan s, Set<QuestionType> supported) {
            return new DocumentQuestionScanResponse(s.questions().stream()
                    .filter(q -> q.type() == null || supported.contains(q.type()))
                    .map(DocumentQuestionResponse::from).toList(), s.complete());
        }
    }

    /** Respuesta a una pregunta: {@code answer} o, en «Varias correctas», {@code answers}. */
    public record AnswerRequest(@Size(max = 1000) String answer,
                                @Size(max = 10) List<@NotNull @Size(max = 500) String> answers) {
    }

    public record AnswerResultResponse(UUID questionId, boolean correct, String correctAnswer, String explanation,
                                       List<String> correctAnswers) {

        public static AnswerResultResponse from(AnswerResult r) {
            return new AnswerResultResponse(r.questionId(), r.correct(), String.join(" · ", r.correctAnswers()),
                    r.explanation(), r.correctAnswers());
        }
    }

    /** Respuestas de la práctica libre por id de pregunta; las de «Varias correctas» van en {@code selections}. */
    public record PracticeCompletionRequest(@NotNull Map<UUID, @Size(max = 1000) String> answers,
                                            Map<UUID, @Size(max = 10) List<@NotNull @Size(max = 500) String>> selections) {

        /** Todas las respuestas como las corrige el dominio. */
        public Map<UUID, String> merged() {
            Map<UUID, String> all = new HashMap<>(answers);
            if (selections != null) {
                selections.forEach((id, list) -> all.put(id, Question.joinAnswers(list)));
            }
            return all;
        }
    }

    public record PracticeResultResponse(int correct, int total, int xpAwarded) {

        public static PracticeResultResponse from(PracticeResult r) {
            return new PracticeResultResponse(r.correct(), r.total(), r.xpAwarded());
        }
    }

    /** Materiales con preguntas para un simulacro de asignatura y los límites al empezarlo. */
    public record MockExamOptionsResponse(List<MockExamSourceResponse> sources, int maxMaterials,
                                          int suggestedQuestions, int maxQuestions) {

        public static MockExamOptionsResponse from(MockExamOptions o) {
            return new MockExamOptionsResponse(o.sources().stream().map(s -> new MockExamSourceResponse(s.materialId(),
                    s.title(), s.originType(), s.questionCount())).toList(), o.maxMaterials(), o.suggestedQuestions(),
                    o.maxQuestions());
        }
    }

    public record MockExamSourceResponse(UUID materialId, String title, StudySourceType originType,
                                         int questionCount) {
    }

    @Schema(name = "QuizStartSessionRequest")
    public record StartSessionRequest(@NotEmpty @Size(max = 10) List<@NotNull UUID> materialIds,
                                      @Min(1) @Max(50) Integer questionCount) {
    }

    /**
     * Pregunta de una sesión. La solución y la explicación solo se incluyen si ya se respondió o
     * si la sesión ha terminado. En «Varias correctas», {@code answers} y {@code correctAnswers} son listas.
     */
    public record SessionQuestionResponse(UUID id, QuestionType type, String statement, List<String> options,
                                          boolean answered, String answer, Boolean correct, String correctAnswer,
                                          String explanation, List<String> answers, List<String> correctAnswers) {
    }

    public record TestSessionResponse(UUID id, UUID materialId, TestSessionStatus status, int currentIndex, int score,
                                      int totalQuestions, int answeredCount, Instant startedAt, Instant completedAt,
                                      boolean xpAwarded, int xpGranted, List<SessionQuestionResponse> questions) {

        public static TestSessionResponse from(TestSessionView v) {
            return from(v, QuestionType.ALL);
        }

        /** Sin las preguntas que la app no sabe pintar (sesión empezada en otro dispositivo, ADR 0058). */
        public static TestSessionResponse from(TestSessionView v, Set<QuestionType> visible) {
            TestSession s = v.session();
            boolean finished = s.status() != TestSessionStatus.IN_PROGRESS;
            Map<UUID, String> answers = s.answers();
            Map<UUID, Boolean> results = s.results();
            List<SessionQuestionResponse> questions = v.questions().stream().filter(q -> visible.contains(q.type()))
                    .map(q -> {
                        boolean answered = results.containsKey(q.id());
                        boolean reveal = answered || finished;
                        String given = answers.get(q.id());
                        return new SessionQuestionResponse(q.id(), q.type(), q.statement(), q.options(), answered,
                                given, results.get(q.id()), reveal ? String.join(" · ", q.correctAnswers()) : null,
                                reveal ? q.explanation() : null, given == null ? null : Question.splitAnswers(given),
                                reveal ? q.correctAnswers() : null);
                    }).toList();
            return new TestSessionResponse(s.id(), s.materialId(), s.status(), s.currentIndex(), s.score(),
                    s.totalQuestions(), results.size(), s.startedAt(), s.completedAt(), s.xpAwarded(), v.xpAwarded(),
                    questions);
        }
    }

    public record TestSessionSummaryResponse(UUID id, UUID materialId, TestSessionStatus status, int score,
                                             int totalQuestions, int answeredCount, Instant startedAt,
                                             Instant completedAt, boolean xpAwarded) {

        public static TestSessionSummaryResponse from(TestSession s) {
            return new TestSessionSummaryResponse(s.id(), s.materialId(), s.status(), s.score(), s.totalQuestions(),
                    s.results().size(), s.startedAt(), s.completedAt(), s.xpAwarded());
        }
    }

    /** Respuesta en una sesión: {@code answer} o, en «Varias correctas», {@code answers}. */
    public record SessionAnswerRequest(@NotNull UUID questionId,
                                       @Size(max = 1000) String answer,
                                       @Min(0) Integer nextIndex,
                                       @Size(max = 10) List<@NotNull @Size(max = 500) String> answers) {
    }

    public record SessionAnswerResponse(AnswerResultResponse result, TestSessionResponse session) {

        public static SessionAnswerResponse from(SessionAnswer a, Set<QuestionType> visible) {
            return new SessionAnswerResponse(AnswerResultResponse.from(a.result()),
                    TestSessionResponse.from(a.view(), visible));
        }
    }
}
