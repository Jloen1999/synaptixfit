import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/domain/enums/test_session_status.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/academic/quiz.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/use_cases/academic/abandon_test_session_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/answer_in_test_session_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/answer_question_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/complete_practice_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/complete_test_session_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/generate_question_bank_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/get_active_test_session_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/get_question_bank_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/get_study_material_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/get_test_sessions_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/review_flashcards_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/start_test_session_use_case.dart';
import 'package:synaptixfit/domain/use_cases/account/get_account_use_case.dart';
import 'package:synaptixfit/presentation/screens/academic/flashcards/bloc/flashcards_bloc.dart';
import 'package:synaptixfit/presentation/screens/academic/free_practice/bloc/free_practice_bloc.dart';
import 'package:synaptixfit/presentation/screens/academic/mock_exam/bloc/mock_exam_bloc.dart';
import 'package:synaptixfit/presentation/screens/academic/practice_hub/bloc/practice_hub_bloc.dart';

import 'academic_fixtures.dart';

class _GetMaterial extends Mock implements GetStudyMaterialUseCaseContract {}

class _GetBank extends Mock implements GetQuestionBankUseCaseContract {}

class _GenerateBank extends Mock
    implements GenerateQuestionBankUseCaseContract {}

class _GetActive extends Mock implements GetActiveTestSessionUseCaseContract {}

class _GetSessions extends Mock implements GetTestSessionsUseCaseContract {}

class _Answer extends Mock implements AnswerQuestionUseCaseContract {}

class _CompletePractice extends Mock
    implements CompletePracticeUseCaseContract {}

class _ReviewFlashcards extends Mock
    implements ReviewFlashcardsUseCaseContract {}

class _Start extends Mock implements StartTestSessionUseCaseContract {}

class _AnswerInSession extends Mock
    implements AnswerInTestSessionUseCaseContract {}

class _Complete extends Mock implements CompleteTestSessionUseCaseContract {}

class _Abandon extends Mock implements AbandonTestSessionUseCaseContract {}

class _GetAccount extends Mock implements GetAccountUseCaseContract {}

void main() {
  late _GetAccount getAccount;

  setUp(() {
    getAccount = _GetAccount();
    when(() => getAccount()).thenAnswer((_) async => const Success(account));
  });

  group('PracticeHubBloc', () {
    late _GetMaterial getMaterial;
    late _GetBank getBank;
    late _GenerateBank generateBank;
    late _GetActive getActive;
    late _GetSessions getSessions;

    setUp(() {
      getMaterial = _GetMaterial();
      getBank = _GetBank();
      generateBank = _GenerateBank();
      getActive = _GetActive();
      getSessions = _GetSessions();
      when(
        () => getMaterial('m1'),
      ).thenAnswer((_) async => const Success(material));
      when(() => getActive('m1')).thenAnswer((_) async => const Success(null));
      when(() => getSessions('m1')).thenAnswer((_) async => const Success([]));
    });

    PracticeHubBloc build() => PracticeHubBloc(
      getMaterial: getMaterial,
      getBank: getBank,
      generateBank: generateBank,
      getActiveSession: getActive,
      getSessions: getSessions,
    );

    blocTest<PracticeHubBloc, PracticeHubState>(
      'sin banco permite generarlo con IA',
      setUp: () {
        when(() => getBank('m1')).thenAnswer((_) async => const Success(null));
        when(
          () => generateBank('m1'),
        ).thenAnswer((_) async => const Success(bank));
      },
      build: build,
      act: (bloc) async {
        bloc.add(const PracticeHubEvent.started('m1'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const PracticeHubEvent.bankRequested());
      },
      expect: () => const [
        PracticeHubState(materialId: 'm1'),
        PracticeHubState(materialId: 'm1', loading: false, material: material),
        PracticeHubState(
          materialId: 'm1',
          loading: false,
          material: material,
          generating: true,
        ),
        PracticeHubState(
          materialId: 'm1',
          loading: false,
          material: material,
          bank: bank,
        ),
      ],
    );

    blocTest<PracticeHubBloc, PracticeHubState>(
      'emite el error si falla el material',
      setUp: () {
        when(
          () => getMaterial('m1'),
        ).thenAnswer((_) async => const Failure(AppError.notFound()));
        when(() => getBank('m1')).thenAnswer((_) async => const Success(bank));
      },
      build: build,
      act: (bloc) => bloc.add(const PracticeHubEvent.started('m1')),
      expect: () => const [
        PracticeHubState(materialId: 'm1'),
        PracticeHubState(
          materialId: 'm1',
          loading: false,
          error: AppError.notFound(),
        ),
      ],
    );
  });

  group('FreePracticeBloc', () {
    late _GetBank getBank;
    late _Answer answer;
    late _CompletePractice complete;
    const correct = AnswerResult(questionId: 'q1', correct: true);

    setUp(() {
      getBank = _GetBank();
      answer = _Answer();
      complete = _CompletePractice();
    });

    FreePracticeBloc build() => FreePracticeBloc(
      getBank: getBank,
      answer: answer,
      complete: complete,
      getAccount: getAccount,
    );

    blocTest<FreePracticeBloc, FreePracticeState>(
      'un banco vacío se muestra como error QUIZ_BANK_EMPTY',
      setUp: () => when(
        () => getBank('m1'),
      ).thenAnswer((_) async => const Success(null)),
      build: build,
      act: (bloc) => bloc.add(const FreePracticeEvent.started('m1')),
      expect: () => const [
        FreePracticeState(),
        FreePracticeState(
          loading: false,
          error: AppError.business('QUIZ_BANK_EMPTY'),
        ),
      ],
    );

    blocTest<FreePracticeBloc, FreePracticeState>(
      'corrige, avanza y al terminar otorga XP y refresca la cuenta',
      setUp: () {
        when(
          () => answer('q1', '4'),
        ).thenAnswer((_) async => const Success(correct));
        when(() => complete('b1', {'q1': '4'})).thenAnswer(
          (_) async => const Success(
            PracticeResult(correct: 1, total: 2, xpAwarded: 10),
          ),
        );
      },
      build: build,
      seed: () => const FreePracticeState(loading: false, bank: bank),
      act: (bloc) async {
        bloc
          ..add(const FreePracticeEvent.answerChanged('4'))
          ..add(const FreePracticeEvent.checked());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const FreePracticeEvent.finished());
      },
      verify: (bloc) {
        expect(bloc.state.results['q1'], correct);
        expect(bloc.state.result?.xpAwarded, 10);
        expect(bloc.state.updatedAccount, account);
      },
    );

    blocTest<FreePracticeBloc, FreePracticeState>(
      'no corrige una respuesta vacía',
      build: build,
      seed: () => const FreePracticeState(loading: false, bank: bank),
      act: (bloc) => bloc.add(const FreePracticeEvent.checked()),
      expect: () => const <FreePracticeState>[],
    );
  });

  group('FlashcardsBloc', () {
    late _GetBank getBank;
    late _ReviewFlashcards reviewFlashcards;

    setUp(() {
      getBank = _GetBank();
      reviewFlashcards = _ReviewFlashcards();
      when(() => getBank('m1')).thenAnswer((_) async => const Success(bank));
    });

    blocTest<FlashcardsBloc, FlashcardsState>(
      'clasifica todas las tarjetas y registra la ronda',
      setUp: () =>
          when(
            () => reviewFlashcards('m1', mastered: 1, doubtful: 0, failed: 1),
          ).thenAnswer(
            (_) async =>
                const Success(FlashcardReviewResult(quality: 3, xpAwarded: 5)),
          ),
      build: () => FlashcardsBloc(
        getBank: getBank,
        reviewFlashcards: reviewFlashcards,
        getAccount: getAccount,
      ),
      act: (bloc) async {
        bloc.add(const FlashcardsEvent.started('m1'));
        await Future<void>.delayed(Duration.zero);
        bloc
          ..add(const FlashcardsEvent.flipped())
          ..add(const FlashcardsEvent.rated(FlashcardRating.mastered))
          ..add(const FlashcardsEvent.rated(FlashcardRating.failed));
      },
      verify: (bloc) {
        expect(bloc.state.finished, isTrue);
        expect(bloc.state.result?.xpAwarded, 5);
        expect(bloc.state.updatedAccount, account);
      },
    );
  });

  group('MockExamBloc', () {
    late _GetActive getActive;
    late _Start start;
    late _AnswerInSession answerInSession;
    late _Complete complete;
    late _Abandon abandon;

    setUp(() {
      getActive = _GetActive();
      start = _Start();
      answerInSession = _AnswerInSession();
      complete = _Complete();
      abandon = _Abandon();
    });

    MockExamBloc build() => MockExamBloc(
      getActive: getActive,
      start: start,
      answer: answerInSession,
      complete: complete,
      abandon: abandon,
      getAccount: getAccount,
    );

    blocTest<MockExamBloc, MockExamState>(
      'reanuda la sesión activa en la primera pregunta sin responder',
      setUp: () {
        final resumed = session.copyWith(
          questions: [
            session.questions.first.copyWith(answered: true, answer: '4'),
            session.questions.last,
          ],
        );
        when(() => getActive('m1')).thenAnswer((_) async => Success(resumed));
      },
      build: build,
      act: (bloc) =>
          bloc.add(const MockExamEvent.started(materialId: 'm1', resume: true)),
      verify: (bloc) {
        expect(bloc.state.index, 1);
        verifyNever(
          () => start(any(), questionCount: any(named: 'questionCount')),
        );
      },
    );

    blocTest<MockExamBloc, MockExamState>(
      'sin sesión activa crea una nueva',
      setUp: () {
        when(
          () => getActive('m1'),
        ).thenAnswer((_) async => const Success(null));
        when(
          () => start(['m1'], questionCount: any(named: 'questionCount')),
        ).thenAnswer((_) async => Success(session));
      },
      build: build,
      act: (bloc) =>
          bloc.add(const MockExamEvent.started(materialId: 'm1', resume: true)),
      expect: () => [
        const MockExamState(),
        MockExamState(loading: false, session: session),
      ],
    );

    blocTest<MockExamBloc, MockExamState>(
      'responde y pasa a la siguiente pregunta',
      setUp: () {
        final answered = session.copyWith(
          answeredCount: 1,
          questions: [
            session.questions.first.copyWith(answered: true, answer: '4'),
            session.questions.last,
          ],
        );
        when(
          () => answerInSession(
            't1',
            questionId: 'q1',
            answer: '4',
            nextIndex: 1,
          ),
        ).thenAnswer(
          (_) async => Success(
            SessionAnswer(
              result: const AnswerResult(questionId: 'q1', correct: true),
              session: answered,
            ),
          ),
        );
      },
      build: build,
      seed: () => MockExamState(loading: false, session: session, draft: '4'),
      act: (bloc) => bloc.add(const MockExamEvent.answerSubmitted()),
      verify: (bloc) {
        expect(bloc.state.index, 1);
        expect(bloc.state.draft, '');
        expect(bloc.state.answered, 1);
      },
    );

    blocTest<MockExamBloc, MockExamState>(
      'al terminar abre los resultados y refresca la cuenta si hubo XP',
      setUp: () => when(() => complete('t1')).thenAnswer(
        (_) async => Success(
          session.copyWith(status: TestSessionStatus.completed, xpGranted: 20),
        ),
      ),
      build: build,
      seed: () => MockExamState(loading: false, session: session),
      act: (bloc) => bloc.add(const MockExamEvent.completed()),
      verify: (bloc) {
        expect(bloc.state.closedSessionId, 't1');
        expect(bloc.state.updatedAccount, account);
      },
    );

    blocTest<MockExamBloc, MockExamState>(
      'abandonar marca la sesión como abandonada',
      setUp: () => when(() => abandon('t1')).thenAnswer(
        (_) async =>
            Success(session.copyWith(status: TestSessionStatus.abandoned)),
      ),
      build: build,
      seed: () => MockExamState(loading: false, session: session),
      act: (bloc) => bloc.add(const MockExamEvent.abandoned()),
      verify: (bloc) => expect(bloc.state.abandoned, isTrue),
    );
  });
}
