import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/domain/enums/ai_document_type.dart';
import 'package:synaptixfit/domain/enums/study_source_type.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/academic/quiz.dart';
import 'package:synaptixfit/domain/models/academic/subject.dart';
import 'package:synaptixfit/domain/models/academic/subject_questions.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/repositories/quiz_repository_contract.dart';
import 'package:synaptixfit/domain/repositories/study_assistant_repository_contract.dart';
import 'package:synaptixfit/domain/repositories/subject_repository_contract.dart';
import 'package:synaptixfit/domain/use_cases/academic/answer_in_test_session_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/complete_practice_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/dont_know_question_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/get_question_bank_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/get_subject_questions_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/get_subject_semester_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/get_teaching_guide_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/load_or_generate_study_document_use_case.dart';

import '../../presentation/screens/academic/academic_fixtures.dart';

class _Assistant extends Mock implements StudyAssistantRepositoryContract {}

class _Subjects extends Mock implements SubjectRepositoryContract {}

class _Quiz extends Mock implements QuizRepositoryContract {}

void main() {
  group('LoadOrGenerateStudyDocumentUseCase', () {
    late _Assistant repo;
    late LoadOrGenerateStudyDocumentUseCase useCase;

    setUp(() {
      repo = _Assistant();
      useCase = LoadOrGenerateStudyDocumentUseCase(repo);
    });

    test('devuelve el documento guardado sin generar', () async {
      when(
        () => repo.getDocument(
          StudySourceType.note,
          'n1',
          AiDocumentType.summary,
        ),
      ).thenAnswer((_) async => const Success(summaryDoc));

      final result = await useCase(
        StudySourceType.note,
        'n1',
        AiDocumentType.summary,
      );

      expect(result.valueOrNull, summaryDoc);
      verifyNever(() => repo.generateDocument(any(), any(), any()));
    });

    test('si no existe (STUDY_DOCUMENT_NOT_FOUND) lo genera', () async {
      when(
        () => repo.getDocument(
          StudySourceType.note,
          'n1',
          AiDocumentType.summary,
        ),
      ).thenAnswer(
        (_) async =>
            const Failure(AppError.business('STUDY_DOCUMENT_NOT_FOUND')),
      );
      when(
        () => repo.generateDocument(
          StudySourceType.note,
          'n1',
          AiDocumentType.summary,
        ),
      ).thenAnswer((_) async => const Success(summaryDoc));

      final result = await useCase(
        StudySourceType.note,
        'n1',
        AiDocumentType.summary,
      );

      expect(result.valueOrNull, summaryDoc);
    });

    test('otros errores no generan', () async {
      when(
        () => repo.getDocument(
          StudySourceType.note,
          'n1',
          AiDocumentType.summary,
        ),
      ).thenAnswer((_) async => const Failure(AppError.network()));

      final result = await useCase(
        StudySourceType.note,
        'n1',
        AiDocumentType.summary,
      );

      expect(result.errorOrNull, const AppError.network());
      verifyNever(() => repo.generateDocument(any(), any(), any()));
    });
  });

  setUpAll(() {
    registerFallbackValue(StudySourceType.note);
    registerFallbackValue(AiDocumentType.summary);
  });

  test('GetTeachingGuideUseCase traduce la guía inexistente a null', () async {
    final repo = _Subjects();
    when(() => repo.getTeachingGuide('s1')).thenAnswer(
      (_) async => const Failure(AppError.business('STUDY_DOCUMENT_NOT_FOUND')),
    );

    final result = await GetTeachingGuideUseCase(repo)('s1');

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull, isNull);
  });

  test('GetQuestionBankUseCase traduce QUIZ_BANK_NOT_FOUND a null', () async {
    final repo = _Quiz();
    when(() => repo.getQuestionBank('m1')).thenAnswer(
      (_) async => const Failure(AppError.business('QUIZ_BANK_NOT_FOUND')),
    );

    final result = await GetQuestionBankUseCase(repo)('m1');

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull, isNull);
  });

  test(
    'GetSubjectSemesterUseCase busca el semestre de la asignatura',
    () async {
      final repo = _Subjects();
      when(() => repo.getSemesters()).thenAnswer(
        (_) async => const Success([
          SubjectSemester(subjectId: 'otra', course: 1, semester: 1),
          SubjectSemester(subjectId: 's1', course: 2, semester: 2),
        ]),
      );

      final result = await GetSubjectSemesterUseCase(repo)('s1');

      expect(
        result.valueOrNull,
        const SubjectSemester(subjectId: 's1', course: 2, semester: 2),
      );
    },
  );

  group('«No lo sé» y «Practicar» (ADR 0063)', () {
    late _Quiz repo;
    const unknown = AnswerResult(
      questionId: 'q1',
      correct: false,
      dontKnow: true,
    );

    setUp(() => repo = _Quiz());

    test('DontKnowQuestionUseCase pide la solución al repositorio', () async {
      when(
        () => repo.dontKnowQuestion('q1'),
      ).thenAnswer((_) async => const Success(unknown));

      final result = await DontKnowQuestionUseCase(repo)('q1');

      expect(result.valueOrNull, unknown);
    });

    test('GetSubjectQuestionsUseCase lee las preguntas de la asignatura', () async {
      when(
        () => repo.getSubjectQuestions('s1'),
      ).thenAnswer((_) async => const Success(SubjectQuestions(total: 2)));

      final result = await GetSubjectQuestionsUseCase(repo)('s1');

      expect(result.valueOrNull?.total, 2);
    });

    test('el simulacro y la práctica libre mandan el «No lo sé»', () async {
      when(
        () => repo.answerInSession(
          't1',
          questionId: 'q1',
          answer: '',
          dontKnow: true,
        ),
      ).thenAnswer(
        (_) async => Success(SessionAnswer(result: unknown, session: session)),
      );
      when(
        () => repo.completePractice('b1', const {}, dontKnow: const {'q1'}),
      ).thenAnswer(
        (_) async =>
            const Success(PracticeResult(correct: 0, total: 1, xpAwarded: 0)),
      );

      final answered = await AnswerInTestSessionUseCase(
        repo,
      )('t1', questionId: 'q1', answer: '', dontKnow: true);
      final practice = await CompletePracticeUseCase(
        repo,
      )('b1', const {}, dontKnow: const {'q1'});

      expect(answered.valueOrNull?.result.dontKnow, isTrue);
      expect(practice.valueOrNull?.total, 1);
    });
  });
}
