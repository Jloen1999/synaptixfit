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
import com.synaptixfit.domain.model.academic.QuestionStanding;
import com.synaptixfit.domain.model.academic.QuestionType;
import com.synaptixfit.domain.model.academic.SessionAnswer;
import com.synaptixfit.domain.model.academic.StudySourceType;
import com.synaptixfit.domain.model.academic.SubjectQuestions;
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

    /**
     * Respuesta a una pregunta: {@code answer} o, en «Varias correctas», {@code answers}. Con {@code dontKnow}
     * verdadero es «No lo sé» (ADR 0063) y no hace falta respuesta.
     */
    public record AnswerRequest(@Size(max = 1000) String answer,
                                @Size(max = 10) List<@NotNull @Size(max = 500) String> answers,
                                Boolean dontKnow) {

        public boolean saysDontKnow() {
            return Boolean.TRUE.equals(dontKnow);
        }
    }

    /** Corrección; {@code dontKnow} si fue «No lo sé» (entonces {@code correct} es falso). */
    public record AnswerResultResponse(UUID questionId, boolean correct, String correctAnswer, String explanation,
                                       List<String> correctAnswers, boolean dontKnow) {

        public static AnswerResultResponse from(AnswerResult r) {
            return new AnswerResultResponse(r.questionId(), r.correct(), String.join(" · ", r.correctAnswers()),
                    r.explanation(), r.correctAnswers(), r.dontKnow());
        }
    }

    /**
     * Respuestas de la práctica libre por id de pregunta; las de «Varias correctas» van en {@code selections} y
     * las contestadas con «No lo sé», en {@code dontKnow} (ADR 0063).
     */
    public record PracticeCompletionRequest(@NotNull Map<UUID, @Size(max = 1000) String> answers,
                                            Map<UUID, @Size(max = 10) List<@NotNull @Size(max = 500) String>> selections,
                                            @Size(max = 200) Set<@NotNull UUID> dontKnow) {

        /** Preguntas con «No lo sé» (vacío si no llega). */
        public Set<UUID> dontKnowIds() {
            return dontKnow == null ? Set.of() : Set.copyOf(dontKnow);
        }

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
     * {@code dontKnow}: se contestó con «No lo sé»; {@code unanswered}: seguía sin contestar al entregar y pasó a
     * «No lo sé» (ADR 0063).
     */
    public record SessionQuestionResponse(UUID id, QuestionType type, String statement, List<String> options,
                                          boolean answered, String answer, Boolean correct, String correctAnswer,
                                          String explanation, List<String> answers, List<String> correctAnswers,
                                          boolean dontKnow, boolean unanswered) {
    }

    /**
     * Sesión de test (ADR 0063). {@code counted} falso: está abandonada (p. ej. se entregó sin ninguna respuesta) y
     * no da nota ni XP. {@code countsIfSubmitted}: si entregarla ahora contaría (tiene alguna respuesta).
     * {@code answeredCount} son las que contestó la persona (sin las que pasaron a «No lo sé» al entregar).
     */
    public record TestSessionResponse(UUID id, UUID materialId, TestSessionStatus status, int currentIndex, int score,
                                      int totalQuestions, int answeredCount, Instant startedAt, Instant completedAt,
                                      boolean xpAwarded, int xpGranted, List<SessionQuestionResponse> questions,
                                      boolean counted, boolean countsIfSubmitted) {

        public static TestSessionResponse from(TestSessionView v) {
            return from(v, QuestionType.ALL);
        }

        /** Sin las preguntas que la app no sabe pintar (sesión empezada en otro dispositivo, ADR 0058). */
        public static TestSessionResponse from(TestSessionView v, Set<QuestionType> visible) {
            TestSession s = v.session();
            boolean finished = s.status() != TestSessionStatus.IN_PROGRESS;
            Map<UUID, String> answers = s.answers();
            Map<UUID, Boolean> results = s.results();
            Set<UUID> dontKnow = s.dontKnowIds();
            Set<UUID> unanswered = s.unansweredAtSubmit();
            List<SessionQuestionResponse> questions = v.questions().stream().filter(q -> visible.contains(q.type()))
                    .map(q -> {
                        boolean answered = results.containsKey(q.id());
                        boolean reveal = answered || finished;
                        boolean unknown = dontKnow.contains(q.id());
                        String given = unknown ? null : answers.get(q.id());
                        return new SessionQuestionResponse(q.id(), q.type(), q.statement(), q.options(), answered,
                                given, results.get(q.id()), reveal ? String.join(" · ", q.correctAnswers()) : null,
                                reveal ? q.explanation() : null, given == null ? null : Question.splitAnswers(given),
                                reveal ? q.correctAnswers() : null, unknown, unanswered.contains(q.id()));
                    }).toList();
            return new TestSessionResponse(s.id(), s.materialId(), s.status(), s.currentIndex(), s.score(),
                    s.totalQuestions(), s.answeredCount(), s.startedAt(), s.completedAt(), s.xpAwarded(),
                    v.xpAwarded(), questions, s.counted(), s.countsIfSubmitted());
        }
    }

    public record TestSessionSummaryResponse(UUID id, UUID materialId, TestSessionStatus status, int score,
                                             int totalQuestions, int answeredCount, Instant startedAt,
                                             Instant completedAt, boolean xpAwarded) {

        public static TestSessionSummaryResponse from(TestSession s) {
            return new TestSessionSummaryResponse(s.id(), s.materialId(), s.status(), s.score(), s.totalQuestions(),
                    s.answeredCount(), s.startedAt(), s.completedAt(), s.xpAwarded());
        }
    }

    /**
     * Respuesta en una sesión: {@code answer} o, en «Varias correctas», {@code answers}; con {@code dontKnow}
     * verdadero, «No lo sé» (ADR 0063).
     */
    public record SessionAnswerRequest(@NotNull UUID questionId,
                                       @Size(max = 1000) String answer,
                                       @Min(0) Integer nextIndex,
                                       @Size(max = 10) List<@NotNull @Size(max = 500) String> answers,
                                       Boolean dontKnow) {

        public boolean saysDontKnow() {
            return Boolean.TRUE.equals(dontKnow);
        }
    }

    /**
     * Preguntas de una asignatura para «Practicar» (ADR 0063), en el orden en que vuelven: primero las de «No lo
     * sé», luego falladas, nuevas y acertadas. {@code toReview}: cuántas tocan repasar; {@code subjectName}, para el
     * título.
     */
    public record SubjectQuestionsResponse(String subjectName, int total, int toReview,
                                           List<SubjectQuestionResponse> questions) {

        public static SubjectQuestionsResponse from(SubjectQuestions s) {
            return new SubjectQuestionsResponse(s.subjectName(), s.questions().size(), s.toReview(),
                    s.questions().stream().map(SubjectQuestionResponse::from).toList());
        }
    }

    /** Pregunta con su solución, el material del que sale y cómo va ({@code standing}). */
    public record SubjectQuestionResponse(QuestionResponse question, UUID materialId, String materialTitle,
                                          QuestionStanding standing, Instant lastAnsweredAt) {

        public static SubjectQuestionResponse from(SubjectQuestions.Item i) {
            return new SubjectQuestionResponse(QuestionResponse.from(i.question()), i.materialId(), i.materialTitle(),
                    i.standing(), i.lastAnsweredAt());
        }
    }

    public record SessionAnswerResponse(AnswerResultResponse result, TestSessionResponse session) {

        public static SessionAnswerResponse from(SessionAnswer a, Set<QuestionType> visible) {
            return new SessionAnswerResponse(AnswerResultResponse.from(a.result()),
                    TestSessionResponse.from(a.view(), visible));
        }
    }
}
