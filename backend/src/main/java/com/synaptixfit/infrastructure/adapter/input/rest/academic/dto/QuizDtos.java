package com.synaptixfit.infrastructure.adapter.input.rest.academic.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import com.synaptixfit.domain.model.academic.AnswerResult;
import com.synaptixfit.domain.model.academic.PracticeResult;
import com.synaptixfit.domain.model.academic.Question;
import com.synaptixfit.domain.model.academic.QuestionBankView;
import com.synaptixfit.domain.model.academic.QuestionType;
import com.synaptixfit.domain.model.academic.SessionAnswer;
import com.synaptixfit.domain.model.academic.TestSession;
import com.synaptixfit.domain.model.academic.TestSessionStatus;
import com.synaptixfit.domain.model.academic.TestSessionView;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/** DTOs de bancos de preguntas, práctica y sesiones de test. */
public final class QuizDtos {

    private QuizDtos() {
    }

    /** Pregunta con su solución (banco completo: flashcards y práctica libre). */
    public record QuestionResponse(UUID id, QuestionType type, String statement, List<String> options, int order,
                                   String correctAnswer, String explanation) {

        public static QuestionResponse from(Question q) {
            return new QuestionResponse(q.id(), q.type(), q.statement(), q.options(), q.order(), q.correctAnswer(),
                    q.explanation());
        }
    }

    public record QuestionBankResponse(UUID id, UUID materialId, Instant generatedAt, boolean xpAwarded,
                                       int questionCount, int attemptedQuestions, int correctQuestions,
                                       List<QuestionResponse> questions) {

        public static QuestionBankResponse from(QuestionBankView v) {
            return new QuestionBankResponse(v.bank().id(), v.bank().materialId(), v.bank().generatedAt(),
                    v.bank().xpAwarded(), v.questions().size(), v.attemptedQuestions(), v.correctQuestions(),
                    v.questions().stream().map(QuestionResponse::from).toList());
        }
    }

    public record AnswerRequest(@NotNull @Size(max = 1000) String answer) {
    }

    public record AnswerResultResponse(UUID questionId, boolean correct, String correctAnswer, String explanation) {

        public static AnswerResultResponse from(AnswerResult r) {
            return new AnswerResultResponse(r.questionId(), r.correct(), r.correctAnswer(), r.explanation());
        }
    }

    /** Respuestas de la práctica libre por id de pregunta. */
    public record PracticeCompletionRequest(@NotNull Map<UUID, @Size(max = 1000) String> answers) {
    }

    public record PracticeResultResponse(int correct, int total, int xpAwarded) {

        public static PracticeResultResponse from(PracticeResult r) {
            return new PracticeResultResponse(r.correct(), r.total(), r.xpAwarded());
        }
    }

    @Schema(name = "QuizStartSessionRequest")

    public record StartSessionRequest(@NotEmpty @Size(max = 10) List<@NotNull UUID> materialIds,
                                      @Min(1) @Max(50) Integer questionCount) {
    }

    /**
     * Pregunta de una sesión. La solución y la explicación solo se incluyen si ya se respondió o
     * si la sesión ha terminado.
     */
    public record SessionQuestionResponse(UUID id, QuestionType type, String statement, List<String> options,
                                          boolean answered, String answer, Boolean correct, String correctAnswer,
                                          String explanation) {
    }

    public record TestSessionResponse(UUID id, UUID materialId, TestSessionStatus status, int currentIndex, int score,
                                      int totalQuestions, int answeredCount, Instant startedAt, Instant completedAt,
                                      boolean xpAwarded, int xpGranted, List<SessionQuestionResponse> questions) {

        public static TestSessionResponse from(TestSessionView v) {
            TestSession s = v.session();
            boolean finished = s.status() != TestSessionStatus.IN_PROGRESS;
            Map<UUID, String> answers = s.answers();
            Map<UUID, Boolean> results = s.results();
            List<SessionQuestionResponse> questions = v.questions().stream().map(q -> {
                boolean answered = results.containsKey(q.id());
                boolean reveal = answered || finished;
                return new SessionQuestionResponse(q.id(), q.type(), q.statement(), q.options(), answered,
                        answers.get(q.id()), results.get(q.id()), reveal ? q.correctAnswer() : null,
                        reveal ? q.explanation() : null);
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

    public record SessionAnswerRequest(@NotNull UUID questionId,
                                       @NotNull @Size(max = 1000) String answer,
                                       @Min(0) Integer nextIndex) {
    }

    public record SessionAnswerResponse(AnswerResultResponse result, TestSessionResponse session) {

        public static SessionAnswerResponse from(SessionAnswer a) {
            return new SessionAnswerResponse(AnswerResultResponse.from(a.result()), TestSessionResponse.from(a.view()));
        }
    }
}
