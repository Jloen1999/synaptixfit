package com.synaptixfit.application.service.academic;

import com.synaptixfit.application.port.input.academic.AbandonTestSessionUseCase;
import com.synaptixfit.application.port.input.academic.AnswerQuestionUseCase;
import com.synaptixfit.application.port.input.academic.AnswerTestQuestionUseCase;
import com.synaptixfit.application.port.input.academic.CompleteBankPracticeUseCase;
import com.synaptixfit.application.port.input.academic.CompleteTestSessionUseCase;
import com.synaptixfit.application.port.input.academic.DontKnowQuestionUseCase;
import com.synaptixfit.application.port.input.academic.GetActiveTestSessionUseCase;
import com.synaptixfit.application.port.input.academic.GetQuestionBankUseCase;
import com.synaptixfit.application.port.input.academic.GetTestSessionUseCase;
import com.synaptixfit.application.port.input.academic.ListTestSessionsUseCase;
import com.synaptixfit.application.port.input.academic.SaveCreatedQuestionsUseCase;
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
import com.synaptixfit.domain.model.academic.QuestionStanding;
import com.synaptixfit.domain.model.academic.QuestionType;
import com.synaptixfit.domain.model.academic.QuestionBankView;
import com.synaptixfit.domain.model.academic.SessionAnswer;
import com.synaptixfit.domain.model.academic.StudyMaterial;
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
import java.util.Comparator;
import java.util.EnumMap;
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
 * una sesión publica {@link TestSessionCompleted} (carga cognitiva e insignias). Guarda lo que crea
 * «Crear preguntas» ({@link QuestionCreationService}, ADR 0058); cada app solo recibe los tipos de pregunta
 * que sabe pintar. «No lo sé» y la entrega de un simulacro (sin respuestas no cuenta; lo sin contestar pasa a
 * «No lo sé») siguen ADR 0063.
 */
public class QuizService implements GetQuestionBankUseCase, SaveCreatedQuestionsUseCase, AnswerQuestionUseCase,
        DontKnowQuestionUseCase, CompleteBankPracticeUseCase, StartTestSessionUseCase, GetTestSessionUseCase, GetActiveTestSessionUseCase,
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
    public QuestionBankView getBank(UUID userId, UUID materialId, Set<QuestionType> visibleTypes) {
        StudyMaterial m = lookups.material(userId, materialId);
        QuestionBank bank = banks.findByMaterial(m.id()).orElseThrow(() -> new QuestionBankNotFoundException(materialId));
        return view(userId, bank, visibleTypes);
    }

    @Override
    public int saveCreatedQuestions(SaveCreatedQuestionsUseCase.Command c) {
        StudyMaterial m = lookups.material(c.userId(), c.materialId());
        String title = lookups.origin(c.userId(), m.originType(), m.originId()).title();
        return practiceBanks.save(c.userId(), m, title, c.mode(), c.questions());
    }

    @Override
    public AnswerResult answerQuestion(UUID userId, UUID questionId, String answer) {
        Question q = banks.findQuestionOfUser(questionId, userId)
                .orElseThrow(() -> new QuestionNotFoundException(questionId));
        return grade(userId, q, answer);
    }

    @Override
    public AnswerResult dontKnow(UUID userId, UUID questionId) {
        Question q = banks.findQuestionOfUser(questionId, userId)
                .orElseThrow(() -> new QuestionNotFoundException(questionId));
        attempts.save(QuestionAttempt.dontKnow(userId, q.id(), clock.instant()));
        return AnswerResult.dontKnow(q);
    }

    @Override
    public PracticeResult completePractice(UUID userId, UUID bankId, Map<UUID, String> answers,
                                           Set<UUID> dontKnow, Set<QuestionType> visibleTypes) {
        QuestionBank bank = banks.findByIdAndUser(bankId, userId)
                .orElseThrow(() -> new QuestionBankNotFoundException(bankId));
        List<Question> questions = visible(banks.findQuestions(bank.id()), visibleTypes);
        if (questions.isEmpty()) {
            throw new QuestionBankEmptyException(bankId);
        }
        Map<UUID, String> given = answers == null ? Map.of() : answers;
        Set<UUID> unknown = dontKnow == null ? Set.of() : dontKnow;
        // Cada «Comprobar» ya dejó su intento corregido: manda ese, no lo que llegue al cerrar (con la solución a
        // la vista se podría mandar la buena y subir la nota). «No lo sé» es una respuesta fallada: cuenta para
        // «todas respondidas», nunca como acierto.
        Map<UUID, QuestionAttempt> latest = QuestionStanding.latest(attempts.findByUserAndQuestions(userId,
                questions.stream().map(Question::id).toList()));
        int correct = (int) questions.stream().filter(q -> {
            if (unknown.contains(q.id()) || given.get(q.id()) == null) {
                return false;
            }
            QuestionAttempt last = latest.get(q.id());
            return last != null ? last.correct() : q.isCorrect(given.get(q.id()));
        }).count();
        boolean allAnswered = questions.stream()
                .allMatch(q -> given.get(q.id()) != null || unknown.contains(q.id()));
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
            chosen.addAll(prioritize(c.userId(), visible(banks.findQuestions(bank.get().id()), c.supportedTypes()),
                    perMaterial));
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
        // Un simulacro entregado sin respuestas no cuenta ni sale en el historial (ADR 0063).
        return sessions.findByUser(userId, materialId, status).stream().filter(TestSession::inHistory).toList();
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
        AnswerResult result;
        if (c.dontKnow()) {
            result = AnswerResult.dontKnow(q);
            session.dontKnow(q.id(), c.nextIndex());
            attempts.save(QuestionAttempt.dontKnow(c.userId(), q.id(), clock.instant()));
        } else {
            result = AnswerResult.graded(q, q.isCorrect(c.answer()));
            session.answer(q.id(), c.answer(), result.correct(), c.nextIndex());
            attempts.save(QuestionAttempt.of(c.userId(), q.id(), result.correct(), clock.instant()));
        }
        return new SessionAnswer(result, view(sessions.save(session), 0));
    }

    /**
     * Entrega la sesión (ADR 0063). Sin ninguna respuesta no cuenta: se abandona y no da nota, ni XP, ni historial,
     * ni toca el repaso ni la carga (no se publica {@link TestSessionCompleted}). Si no, lo sin contestar pasa a
     * «No lo sé» (y vuelve antes). Entregar otra vez una sesión ya cerrada da 409.
     */
    @Override
    public TestSessionView completeSession(UUID userId, UUID sessionId) {
        TestSession session = session(userId, sessionId);
        Instant now = clock.instant();
        if (!session.countsIfSubmitted()) {
            session.abandon(now);
            return view(sessions.save(session), 0);
        }
        for (UUID unanswered : session.complete(now)) {
            attempts.save(QuestionAttempt.dontKnow(userId, unanswered, now));
        }
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
        return AnswerResult.graded(q, correct);
    }

    /** Solo las preguntas de los tipos que la app sabe pintar (las antiguas no conocen «Varias correctas»). */
    private static List<Question> visible(List<Question> questions, Set<QuestionType> types) {
        return questions.stream().filter(q -> types.contains(q.type())).toList();
    }

    /**
     * Banco con sus preguntas en el orden en que vuelven (ADR 0063): «No lo sé», falladas, nuevas y acertadas; dentro
     * de cada grupo, el orden del banco. Así la práctica libre y las tarjetas empiezan por lo que toca repasar.
     */
    private QuestionBankView view(UUID userId, QuestionBank bank, Set<QuestionType> visibleTypes) {
        List<Question> questions = visible(banks.findQuestions(bank.id()), visibleTypes);
        List<QuestionAttempt> history = questions.isEmpty() ? List.of()
                : attempts.findByUserAndQuestions(userId, questions.stream().map(Question::id).toList());
        // «Acertadas» como en el resto (ADR 0063): las que se acertaron en su último intento.
        Map<UUID, QuestionAttempt> latest = QuestionStanding.latest(history);
        int attempted = latest.size();
        int correct = (int) latest.values().stream().filter(QuestionAttempt::correct).count();
        List<Question> ordered = questions.stream()
                .sorted(Comparator.comparing((Question q) -> QuestionStanding.of(latest.get(q.id())),
                        QuestionStanding.COMES_BACK_FIRST).thenComparingInt(Question::order))
                .toList();
        return new QuestionBankView(bank, ordered, attempted, correct);
    }

    /** Preguntas en el orden de la sesión; las borradas al regenerar el banco se omiten. */
    private TestSessionView view(TestSession session, int xp) {
        Map<UUID, Question> byId = banks.findQuestionsByIds(session.questionIds()).stream()
                .collect(Collectors.toMap(Question::id, Function.identity()));
        List<Question> ordered = session.questionIds().stream().map(byId::get).filter(q -> q != null).toList();
        return new TestSessionView(session, ordered, xp);
    }

    /**
     * Elige las preguntas que vuelven antes según su último intento ({@link QuestionStanding}): «No lo sé»,
     * falladas, nuevas y, por último, acertadas; cada grupo se baraja.
     */
    private List<Question> prioritize(UUID userId, List<Question> questions, int limit) {
        if (questions.isEmpty()) {
            return List.of();
        }
        Map<UUID, QuestionAttempt> latest = QuestionStanding.latest(attempts.findByUserAndQuestions(userId,
                questions.stream().map(Question::id).toList()));
        Map<QuestionStanding, List<Question>> groups = new EnumMap<>(QuestionStanding.class);
        for (Question q : questions) {
            groups.computeIfAbsent(QuestionStanding.of(latest.get(q.id())), k -> new ArrayList<>()).add(q);
        }
        List<Question> ordered = new ArrayList<>();
        groups.keySet().stream().sorted(QuestionStanding.COMES_BACK_FIRST).forEach(standing -> {
            List<Question> group = groups.get(standing);
            Collections.shuffle(group, random);
            ordered.addAll(group);
        });
        return ordered.subList(0, Math.min(limit, ordered.size()));
    }
}
