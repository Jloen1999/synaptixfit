package com.synaptixfit.application.service.academic;

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
import com.synaptixfit.application.port.input.gamification.AwardExperienceUseCase;
import com.synaptixfit.domain.event.academic.TestSessionCompleted;
import com.synaptixfit.domain.exception.FieldValidationException;
import com.synaptixfit.domain.exception.academic.QuestionBankEmptyException;
import com.synaptixfit.domain.exception.academic.QuestionBankNotFoundException;
import com.synaptixfit.domain.exception.academic.QuestionNotFoundException;
import com.synaptixfit.domain.exception.academic.TestSessionNotFoundException;
import com.synaptixfit.domain.exception.academic.TestSessionNotInProgressException;
import com.synaptixfit.domain.model.academic.MockExamOptions;
import com.synaptixfit.domain.model.academic.AnswerResult;
import com.synaptixfit.domain.model.academic.PracticeRewards;
import com.synaptixfit.domain.model.academic.PracticeResult;
import com.synaptixfit.domain.model.academic.Question;
import com.synaptixfit.domain.model.academic.QuestionAttempt;
import com.synaptixfit.domain.model.academic.QuestionBank;
import com.synaptixfit.domain.model.academic.QuestionBankView;
import com.synaptixfit.domain.model.academic.SessionAnswer;
import com.synaptixfit.domain.model.academic.StudyMaterial;
import com.synaptixfit.domain.model.academic.StudySourceRef;
import com.synaptixfit.domain.model.academic.TestSession;
import com.synaptixfit.domain.model.academic.TestSessionStatus;
import com.synaptixfit.domain.model.academic.TestSessionView;
import com.synaptixfit.domain.port.output.academic.AiDocumentRepositoryPort;
import com.synaptixfit.domain.port.output.academic.NoteRepositoryPort;
import com.synaptixfit.domain.port.output.academic.QuestionAttemptRepositoryPort;
import com.synaptixfit.domain.port.output.academic.QuestionBankRepositoryPort;
import com.synaptixfit.domain.port.output.academic.StudyAssistantPort;
import com.synaptixfit.domain.port.output.academic.StudyDocumentCodecPort;
import com.synaptixfit.domain.port.output.academic.StudyMaterialRepositoryPort;
import com.synaptixfit.domain.port.output.academic.SubjectFileRepositoryPort;
import com.synaptixfit.domain.port.output.academic.SubjectRepositoryPort;
import com.synaptixfit.domain.port.output.academic.TestSessionRepositoryPort;
import com.synaptixfit.domain.port.output.storage.FileStoragePort;
import com.synaptixfit.domain.port.output.event.DomainEventPublisherPort;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashSet;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Random;
import java.util.Set;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * Bancos de preguntas, práctica libre y sesiones de test persistentes (práctica y simulacro).
 * Las respuestas se corrigen en el servidor. XP con anti-farmeo: una vez por banco en la
 * práctica libre y una vez por sesión completada con todas las preguntas respondidas. Al terminar
 * una sesión publica {@link TestSessionCompleted} (carga cognitiva e insignias).
 */
public class QuizService implements GetQuestionBankUseCase, GenerateQuestionBankUseCase, AnswerQuestionUseCase,
        CompleteBankPracticeUseCase, StartTestSessionUseCase, GetTestSessionUseCase, GetActiveTestSessionUseCase,
        ListTestSessionsUseCase, AnswerTestQuestionUseCase, CompleteTestSessionUseCase, AbandonTestSessionUseCase {

    static final int DEFAULT_QUESTION_COUNT = MockExamOptions.DEFAULT_QUESTIONS;
    static final int MAX_QUESTION_COUNT = MockExamOptions.MAX_QUESTIONS;
    static final int MAX_MATERIALS = MockExamOptions.MAX_MATERIALS;
    static final int COMBINED_TARGET = MockExamOptions.SUGGESTED_QUESTIONS;

    private final QuestionBankRepositoryPort banks;
    private final QuestionAttemptRepositoryPort attempts;
    private final TestSessionRepositoryPort sessions;
    private final AwardExperienceUseCase awardExperience;
    private final DomainEventPublisherPort events;
    private final Clock clock;
    private final Random random;
    private final AcademicLookups lookups;
    private final PracticeBankGenerator practiceBanks;

    public QuizService(QuestionBankRepositoryPort banks, QuestionAttemptRepositoryPort attempts,
                       TestSessionRepositoryPort sessions, StudyMaterialRepositoryPort materials,
                       SubjectRepositoryPort subjects, NoteRepositoryPort notes, SubjectFileRepositoryPort files,
                       AiDocumentRepositoryPort aiDocuments, StudyDocumentCodecPort codec,
                       StudyAssistantPort assistant, FileStoragePort storage,
                       AwardExperienceUseCase awardExperience, DomainEventPublisherPort events, Clock clock,
                       Random random) {
        this.banks = banks;
        this.events = events;
        this.attempts = attempts;
        this.sessions = sessions;
        this.awardExperience = awardExperience;
        this.clock = clock;
        this.random = random;
        this.lookups = new AcademicLookups(subjects, notes, files, materials, storage, clock);
        this.practiceBanks = new PracticeBankGenerator(banks, aiDocuments, codec, assistant, clock);
    }

    // ------------------------------------------------------------------ bancos

    @Override
    public QuestionBankView getBank(UUID userId, UUID materialId) {
        StudyMaterial m = lookups.material(userId, materialId);
        QuestionBank bank = banks.findByMaterial(m.id()).orElseThrow(() -> new QuestionBankNotFoundException(materialId));
        return view(userId, bank);
    }

    @Override
    public QuestionBankView generateBank(UUID userId, UUID materialId) {
        StudyMaterial m = lookups.material(userId, materialId);
        AcademicLookups.ResolvedSource source = lookups.resolve(userId, new StudySourceRef(m.originType(),
                m.originId()));
        practiceBanks.generate(userId, m, source);
        return view(userId, banks.findByMaterial(m.id()).orElseThrow(() -> new QuestionBankNotFoundException(materialId)));
    }

    @Override
    public AnswerResult answerQuestion(UUID userId, UUID questionId, String answer) {
        Question q = banks.findQuestionOfUser(questionId, userId)
                .orElseThrow(() -> new QuestionNotFoundException(questionId));
        return grade(userId, q, answer);
    }

    @Override
    public PracticeResult completePractice(UUID userId, UUID bankId, Map<UUID, String> answers) {
        QuestionBank bank = banks.findByIdAndUser(bankId, userId)
                .orElseThrow(() -> new QuestionBankNotFoundException(bankId));
        List<Question> questions = banks.findQuestions(bank.id());
        if (questions.isEmpty()) {
            throw new QuestionBankEmptyException(bankId);
        }
        Map<UUID, String> given = answers == null ? Map.of() : answers;
        int correct = (int) questions.stream().filter(q -> q.isCorrect(given.get(q.id()))).count();
        boolean allAnswered = questions.stream().allMatch(q -> given.get(q.id()) != null);
        int xp = 0;
        if (allAnswered && !bank.xpAwarded()) {
            banks.save(bank.withXpAwarded());
            // Un banco solo da XP una vez (bank.xpAwarded): no entra en el tope diario de tests.
            xp = PracticeRewards.practiceXp(correct, questions.size(), 0);
            if (xp > 0) {
                awardExperience.award(userId, xp);
            }
        }
        return new PracticeResult(correct, questions.size(), xp);
    }

    // ------------------------------------------------------------------ sesiones

    @Override
    public TestSessionView startSession(StartTestSessionUseCase.Command c) {
        List<UUID> materialIds = c.materialIds() == null ? List.of()
                : List.copyOf(new LinkedHashSet<>(c.materialIds()));
        if (materialIds.isEmpty() || materialIds.size() > MAX_MATERIALS) {
            throw new FieldValidationException("materialIds", "INVALID_LENGTH",
                    "between 1 and " + MAX_MATERIALS + " materials are required");
        }
        int requested = c.questionCount() == null ? DEFAULT_QUESTION_COUNT : c.questionCount();
        if (requested < 1 || requested > MAX_QUESTION_COUNT) {
            throw new FieldValidationException("questionCount", "OUT_OF_RANGE",
                    "questionCount must be between 1 and " + MAX_QUESTION_COUNT);
        }
        List<StudyMaterial> selected = materialIds.stream().map(id -> lookups.material(c.userId(), id)).toList();
        int perMaterial = selected.size() == 1 ? requested
                : c.questionCount() != null ? Math.max(1, Math.round((float) requested / selected.size()))
                : Math.max(3, Math.min(15, Math.round((float) COMBINED_TARGET / selected.size())));

        List<Question> chosen = new ArrayList<>();
        for (StudyMaterial m : selected) {
            Optional<QuestionBank> bank = banks.findByMaterial(m.id());
            if (bank.isEmpty()) {
                if (selected.size() == 1) {
                    throw new QuestionBankNotFoundException(m.id());
                }
                continue;
            }
            chosen.addAll(prioritize(c.userId(), banks.findQuestions(bank.get().id()), perMaterial));
        }
        if (chosen.isEmpty()) {
            throw new QuestionBankEmptyException(materialIds.getFirst());
        }
        Collections.shuffle(chosen, random);
        TestSession session = sessions.save(TestSession.start(c.userId(), selected.getFirst().id(),
                chosen.stream().map(Question::id).toList(), clock.instant()));
        return new TestSessionView(session, chosen, 0);
    }

    @Override
    public TestSessionView getSession(UUID userId, UUID sessionId) {
        return view(session(userId, sessionId), 0);
    }

    @Override
    public Optional<TestSessionView> findActiveSession(UUID userId, UUID materialId) {
        StudyMaterial m = lookups.material(userId, materialId);
        return sessions.findActive(userId, m.id()).map(s -> view(s, 0));
    }

    @Override
    public List<TestSession> listSessions(UUID userId, UUID materialId, TestSessionStatus status) {
        if (materialId != null) {
            lookups.material(userId, materialId);
        }
        return sessions.findByUser(userId, materialId, status);
    }

    @Override
    public SessionAnswer answer(AnswerTestQuestionUseCase.Command c) {
        TestSession session = session(c.userId(), c.sessionId());
        if (session.status() != TestSessionStatus.IN_PROGRESS) {
            throw new TestSessionNotInProgressException(session.id());
        }
        if (!session.questionIds().contains(c.questionId())) {
            throw new QuestionNotFoundException(c.questionId());
        }
        Question q = banks.findQuestionsByIds(List.of(c.questionId())).stream().findFirst()
                .orElseThrow(() -> new QuestionNotFoundException(c.questionId()));
        AnswerResult result = new AnswerResult(q.id(), q.isCorrect(c.answer()), q.correctAnswer(), q.explanation());
        session.answer(q.id(), c.answer(), result.correct(), c.nextIndex());
        attempts.save(QuestionAttempt.of(c.userId(), q.id(), result.correct(), clock.instant()));
        return new SessionAnswer(result, view(sessions.save(session), 0));
    }

    @Override
    public TestSessionView completeSession(UUID userId, UUID sessionId) {
        TestSession session = session(userId, sessionId);
        session.complete(clock.instant());
        int xp = 0;
        if (session.canClaimXp()) {
            xp = PracticeRewards.practiceXp(session.score(), session.totalQuestions(), rewardedLastDay(userId));
            if (xp > 0) {
                session.claimXp();
            }
        }
        TestSession saved = sessions.save(session);
        if (xp > 0) {
            awardExperience.award(userId, xp);
        }
        events.publish(new TestSessionCompleted(userId, saved.id(), saved.materialId(), saved.score(),
                saved.totalQuestions(), clock.instant()));
        return view(saved, xp);
    }

    /** Tests que dieron XP en las últimas 24 h (para el tope de {@link PracticeRewards}). */
    private int rewardedLastDay(UUID userId) {
        Instant since = clock.instant().minus(Duration.ofDays(1));
        return (int) sessions.findByUser(userId, null, TestSessionStatus.COMPLETED).stream()
                .filter(s -> s.xpAwarded() && s.completedAt() != null && s.completedAt().isAfter(since))
                .count();
    }

    @Override
    public TestSessionView abandonSession(UUID userId, UUID sessionId) {
        TestSession session = session(userId, sessionId);
        session.abandon(clock.instant());
        return view(sessions.save(session), 0);
    }

    // ------------------------------------------------------------------ apoyo

    private TestSession session(UUID userId, UUID sessionId) {
        return sessions.findByIdAndUser(sessionId, userId)
                .orElseThrow(() -> new TestSessionNotFoundException(sessionId));
    }

    private AnswerResult grade(UUID userId, Question q, String answer) {
        boolean correct = q.isCorrect(answer);
        attempts.save(QuestionAttempt.of(userId, q.id(), correct, clock.instant()));
        return new AnswerResult(q.id(), correct, q.correctAnswer(), q.explanation());
    }

    private QuestionBankView view(UUID userId, QuestionBank bank) {
        List<Question> questions = banks.findQuestions(bank.id());
        List<QuestionAttempt> history = questions.isEmpty() ? List.of()
                : attempts.findByUserAndQuestions(userId, questions.stream().map(Question::id).toList());
        Set<UUID> attempted = new HashSet<>();
        Set<UUID> correct = new HashSet<>();
        for (QuestionAttempt a : history) {
            attempted.add(a.questionId());
            if (a.correct()) {
                correct.add(a.questionId());
            }
        }
        return new QuestionBankView(bank, questions, attempted.size(), correct.size());
    }

    /** Preguntas en el orden de la sesión; las borradas al regenerar el banco se omiten. */
    private TestSessionView view(TestSession session, int xp) {
        Map<UUID, Question> byId = banks.findQuestionsByIds(session.questionIds()).stream()
                .collect(Collectors.toMap(Question::id, Function.identity()));
        List<Question> ordered = session.questionIds().stream().map(byId::get).filter(q -> q != null).toList();
        return new TestSessionView(session, ordered, xp);
    }

    /**
     * Prioriza las preguntas nunca acertadas (falladas), después las no intentadas y por último
     * las ya acertadas; cada grupo se baraja.
     */
    private List<Question> prioritize(UUID userId, List<Question> questions, int limit) {
        if (questions.isEmpty()) {
            return List.of();
        }
        List<QuestionAttempt> history = attempts.findByUserAndQuestions(userId,
                questions.stream().map(Question::id).toList());
        Set<UUID> attempted = history.stream().map(QuestionAttempt::questionId).collect(Collectors.toSet());
        Set<UUID> correct = history.stream().filter(QuestionAttempt::correct).map(QuestionAttempt::questionId)
                .collect(Collectors.toSet());
        List<Question> failed = new ArrayList<>();
        List<Question> fresh = new ArrayList<>();
        List<Question> known = new ArrayList<>();
        for (Question q : questions) {
            if (!attempted.contains(q.id())) {
                fresh.add(q);
            } else if (correct.contains(q.id())) {
                known.add(q);
            } else {
                failed.add(q);
            }
        }
        Collections.shuffle(failed, random);
        Collections.shuffle(fresh, random);
        Collections.shuffle(known, random);
        List<Question> ordered = new ArrayList<>(failed);
        ordered.addAll(fresh);
        ordered.addAll(known);
        return ordered.subList(0, Math.min(limit, ordered.size()));
    }
}
