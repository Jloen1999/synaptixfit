import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/app/di/app_di.dart';
import 'package:synaptixfit/domain/enums/question_standing.dart';
import 'package:synaptixfit/domain/enums/question_type.dart';
import 'package:synaptixfit/domain/enums/test_session_status.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/academic/quiz.dart';
import 'package:synaptixfit/domain/models/academic/subject_questions.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/use_cases/academic/answer_in_test_session_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/answer_question_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/complete_test_session_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/dont_know_question_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/get_active_test_session_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/get_due_study_materials_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/get_subject_questions_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/start_test_session_use_case.dart';
import 'package:synaptixfit/domain/use_cases/account/get_account_use_case.dart';
import 'package:synaptixfit/presentation/l10n/gen_l10n/app_localizations.dart';
import 'package:synaptixfit/presentation/screens/academic/mock_exam/bloc/mock_exam_bloc.dart';
import 'package:synaptixfit/presentation/screens/academic/mock_exam/page/mock_exam_page.dart';
import 'package:synaptixfit/presentation/screens/academic/subject_practice/bloc/subject_practice_bloc.dart';
import 'package:synaptixfit/presentation/screens/academic/subject_practice/page/subject_practice_page.dart';
import 'package:synaptixfit/presentation/screens/academic/widgets/question_view.dart';
import 'package:synaptixfit/presentation/theme/app_theme.dart';

import 'academic_fixtures.dart';

class _GetQuestions extends Mock implements GetSubjectQuestionsUseCaseContract {}

class _GetDue extends Mock implements GetDueStudyMaterialsUseCaseContract {}

class _Answer extends Mock implements AnswerQuestionUseCaseContract {}

class _DontKnow extends Mock implements DontKnowQuestionUseCaseContract {}

class _GetActive extends Mock implements GetActiveTestSessionUseCaseContract {}

class _Start extends Mock implements StartTestSessionUseCaseContract {}

class _AnswerInSession extends Mock
    implements AnswerInTestSessionUseCaseContract {}

class _Complete extends Mock implements CompleteTestSessionUseCaseContract {}

class _GetAccount extends Mock implements GetAccountUseCaseContract {}

const _multi = Question(
  id: 'q3',
  type: QuestionType.multipleAnswer,
  statement: '¿Cuáles agregan filas?',
  options: ['COUNT', 'JOIN', 'AVG'],
  order: 0,
  correctAnswer: 'COUNT · AVG',
  correctAnswers: ['COUNT', 'AVG'],
);

/// En el orden del servidor: primero las que vuelven antes.
const _questions = SubjectQuestions(
  subjectName: 'Bases de datos',
  total: 3,
  toReview: 1,
  questions: [
    SubjectQuestion(
      question: _multi,
      materialId: 'm2',
      materialTitle: 'SQL',
      standing: QuestionStanding.dontKnow,
    ),
    SubjectQuestion(
      question: question2,
      materialId: 'm1',
      materialTitle: 'Límites',
      standing: QuestionStanding.fresh,
    ),
    SubjectQuestion(
      question: question1,
      materialId: 'm1',
      materialTitle: 'Límites',
      standing: QuestionStanding.correct,
    ),
  ],
);

const _dontKnowResult = AnswerResult(
  questionId: 'q3',
  correct: false,
  correctAnswers: ['COUNT', 'AVG'],
  dontKnow: true,
);

/// Botón relleno (también los de icono, que son una subclase).
Finder _filled([String? text]) {
  final buttons = find.byWidgetPredicate((w) => w is FilledButton);
  return text == null
      ? buttons
      : find.ancestor(of: find.text(text), matching: buttons);
}

/// Baja por la página hasta que [finder] se ve entero.
Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    150,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

/// «Practicar» de la asignatura (ADR 0063): bloc, pantalla y accesibilidad.
void main() {
  late _GetQuestions getQuestions;
  late _GetDue getDue;
  late _Answer answer;
  late _DontKnow dontKnow;

  setUp(() {
    getQuestions = _GetQuestions();
    getDue = _GetDue();
    answer = _Answer();
    dontKnow = _DontKnow();
    when(
      () => getQuestions('s1'),
    ).thenAnswer((_) async => const Success(_questions));
    when(
      () => getDue(limit: any(named: 'limit')),
    ).thenAnswer((_) async => const Success([material]));
    when(() => dontKnow('q3')).thenAnswer(
      (_) async => const Success(_dontKnowResult),
    );
  });

  SubjectPracticeBloc build() => SubjectPracticeBloc(
    getQuestions: getQuestions,
    getDue: getDue,
    answer: answer,
    dontKnow: dontKnow,
  );

  group('SubjectPracticeBloc', () {
    blocTest<SubjectPracticeBloc, SubjectPracticeState>(
      'carga las preguntas y los repasos de hoy de la asignatura',
      build: build,
      act: (bloc) => bloc.add(const SubjectPracticeEvent.started('s1')),
      verify: (bloc) {
        expect(bloc.state.loading, isFalse);
        expect(bloc.state.all, hasLength(3));
        expect(bloc.state.due, [material]);
        expect(bloc.state.materials.map((m) => m.id), ['m2', 'm1']);
        expect(bloc.state.materials.first.toReview, 1);
        expect(bloc.state.types, hasLength(3));
      },
    );

    blocTest<SubjectPracticeBloc, SubjectPracticeState>(
      'filtra por cómo van, tipo, tema y texto, y quita los filtros',
      build: build,
      act: (bloc) async {
        bloc.add(const SubjectPracticeEvent.started('s1'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(
          const SubjectPracticeEvent.standingChanged(
            PracticeListFilter.toReview,
          ),
        );
        await Future<void>.delayed(Duration.zero);
        expect(bloc.state.visible.map((i) => i.question.id), ['q3']);
        bloc
          ..add(const SubjectPracticeEvent.filtersCleared())
          ..add(const SubjectPracticeEvent.materialChanged('m1'))
          ..add(
            const SubjectPracticeEvent.typeChanged(QuestionType.fillInBlank),
          );
        await Future<void>.delayed(Duration.zero);
        expect(bloc.state.visible.map((i) => i.question.id), ['q2']);
        bloc
          ..add(const SubjectPracticeEvent.filtersCleared())
          ..add(const SubjectPracticeEvent.queryChanged('sql'));
      },
      verify: (bloc) {
        expect(bloc.state.visible.map((i) => i.question.id), ['q3']);
        expect(bloc.state.filtered, isTrue);
      },
    );

    blocTest<SubjectPracticeBloc, SubjectPracticeState>(
      '«No lo sé» guarda la solución sin respuesta y al volver a leer se '
      'limpia',
      build: build,
      act: (bloc) async {
        bloc.add(const SubjectPracticeEvent.started('s1'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const SubjectPracticeEvent.dontKnow('q3'));
        await Future<void>.delayed(Duration.zero);
        expect(bloc.state.results['q3'], _dontKnowResult);
        expect(bloc.state.answers, isEmpty);
        bloc.add(const SubjectPracticeEvent.refreshed());
      },
      verify: (bloc) {
        expect(bloc.state.results, isEmpty);
        verify(() => dontKnow('q3')).called(1);
      },
    );

    blocTest<SubjectPracticeBloc, SubjectPracticeState>(
      'contesta una pregunta y guarda lo contestado; un fallo queda en '
      'actionError',
      setUp: () {
        when(() => answer('q1', '4')).thenAnswer(
          (_) async =>
              const Success(AnswerResult(questionId: 'q1', correct: true)),
        );
        when(
          () => answer('q2', 'Roma'),
        ).thenAnswer((_) async => const Failure(AppError.network()));
      },
      build: build,
      seed: () => const SubjectPracticeState(
        loading: false,
        subjectId: 's1',
        questions: _questions,
      ),
      act: (bloc) async {
        bloc.add(
          const SubjectPracticeEvent.answered(questionId: 'q1', answer: ' 4 '),
        );
        await Future<void>.delayed(Duration.zero);
        bloc.add(
          const SubjectPracticeEvent.answered(questionId: 'q2', answer: 'Roma'),
        );
      },
      verify: (bloc) {
        expect(bloc.state.answers, {'q1': '4'});
        expect(bloc.state.results['q1']?.correct, isTrue);
        expect(bloc.state.actionError, const AppError.network());
        expect(bloc.state.checkingId, isNull);
      },
    );

    blocTest<SubjectPracticeBloc, SubjectPracticeState>(
      'si fallan las preguntas al entrar, error con reintento',
      setUp: () => when(
        () => getQuestions('s1'),
      ).thenAnswer((_) async => const Failure(AppError.network())),
      build: build,
      act: (bloc) => bloc.add(const SubjectPracticeEvent.started('s1')),
      verify: (bloc) => expect(bloc.state.error, const AppError.network()),
    );
  });

  group('pantalla', () {
    late SubjectPracticeBloc current;
    setUp(
      () => getIt.registerFactory<SubjectPracticeBloc>(() => current = build()),
    );
    tearDown(() => getIt.unregister<SubjectPracticeBloc>());

    Future<void> pump(
      WidgetTester tester, {
      double width = 420,
      double textScale = 1,
      ThemeData? theme,
    }) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: theme ?? AppTheme.light,
          locale: const Locale('es'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: const SubjectPracticePage(subjectId: 's1'),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('una sola acción principal: con repasos hoy, «Repasar»; '
        'las demás formas son filas', (tester) async {
      await pump(tester);
      expect(_filled(), findsOneWidget);
      expect(_filled('Repasar'), findsOneWidget);
      expect(find.text('Repaso de hoy'), findsOneWidget);
      expect(find.text('Práctica libre'), findsOneWidget);
      expect(find.text('Simulacro'), findsOneWidget);
      expect(find.text('3 preguntas · 1 por repasar'), findsOneWidget);
      // El título lleva la asignatura.
      expect(find.text('Practicar · Bases de datos'), findsOneWidget);
    });

    testWidgets('sin repasos, la principal es practicar y una nota dice que '
        'hoy no toca', (tester) async {
      when(
        () => getDue(limit: any(named: 'limit')),
      ).thenAnswer((_) async => const Success([]));
      await pump(tester);
      expect(_filled('Empezar a practicar'), findsOneWidget);
      expect(
        find.text('Hoy no te toca ningún repaso en esta asignatura.'),
        findsOneWidget,
      );
    });

    testWidgets('sin preguntas ni repasos, la principal es crear preguntas', (
      tester,
    ) async {
      when(
        () => getQuestions('s1'),
      ).thenAnswer((_) async => const Success(SubjectQuestions()));
      when(
        () => getDue(limit: any(named: 'limit')),
      ).thenAnswer((_) async => const Success([]));
      await pump(tester);
      expect(_filled('Crear preguntas'), findsOneWidget);
      expect(
        find.text('Aún no tienes preguntas de esta asignatura'),
        findsOneWidget,
      );
    });

    testWidgets('la lista dice cómo va cada una con texto y se filtra', (
      tester,
    ) async {
      await pump(tester);
      // Lista perezosa: se baja hasta cada fila.
      for (final text in ['No la sabías', 'Nueva', 'Acertada']) {
        await _scrollTo(tester, find.text(text));
        expect(find.text(text), findsOneWidget);
      }
      await _scrollTo(tester, find.text('Por repasar').first);
      await tester.tap(find.text('Por repasar').first);
      await tester.pumpAndSettle();
      expect(find.text('1 pregunta'), findsOneWidget);
      expect(find.text('Capital de Francia'), findsNothing);
    });

    testWidgets('una pregunta se abre y «No lo sé» enseña la respuesta y que '
        'volverá antes', (tester) async {
      await pump(tester);
      await _scrollTo(tester, find.text('¿Cuáles agregan filas?'));
      await tester.tap(find.text('¿Cuáles agregan filas?'));
      await tester.pumpAndSettle();
      expect(find.byType(QuestionSheet), findsOneWidget);
      expect(find.text('Elige todas las correctas'), findsOneWidget);
      await tester.tap(find.text('No lo sé'));
      await tester.pumpAndSettle();
      expect(find.text('No lo sabías'), findsOneWidget);
      expect(find.text('Respuesta correcta: COUNT · AVG'), findsOneWidget);
      expect(find.text('Volverá antes para que la repases.'), findsOneWidget);
      // Hay más en la lista: «Siguiente», en el hueco de «Comprobar».
      expect(find.text('Comprobar'), findsNothing);
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();
      expect(find.text('Pregunta 2 de 3'), findsOneWidget);
      expect(find.text('Capital de Francia'), findsWidgets);
    });

    testWidgets('en la última, «Volver a la lista» con borde cierra la hoja', (
      tester,
    ) async {
      when(() => answer('q1', '4')).thenAnswer(
        (_) async =>
            const Success(AnswerResult(questionId: 'q1', correct: true)),
      );
      await pump(tester);
      await _scrollTo(tester, find.text('¿2+2?'));
      await tester.tap(find.text('¿2+2?'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('4'));
      await tester.pump();
      await tester.tap(find.text('Comprobar'));
      await tester.pumpAndSettle();
      final back = find.ancestor(
        of: find.text('Volver a la lista'),
        matching: find.byWidgetPredicate((w) => w is OutlinedButton),
      );
      expect(back, findsOneWidget);
      expect(_filled('Volver a la lista'), findsNothing);
      await tester.tap(back);
      await tester.pumpAndSettle();
      expect(find.byType(QuestionSheet), findsNothing);
    });

    testWidgets('sin resultados con filtros puestos, «Quitar filtros» vuelve '
        'los desplegables a «Todos»', (tester) async {
      await pump(tester);
      current
        ..add(const SubjectPracticeEvent.typeChanged(QuestionType.fillInBlank))
        ..add(const SubjectPracticeEvent.materialChanged('m1'));
      await tester.pumpAndSettle();
      expect(find.text('Todos los tipos'), findsNothing);
      await _scrollTo(tester, find.byType(TextField).first);
      await tester.enterText(find.byType(TextField).first, 'zzz');
      // El buscador espera un poco antes de filtrar.
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(find.text('1 pregunta'), findsNothing);
      await _scrollTo(tester, find.text('Quitar filtros'));
      await tester.tap(find.text('Quitar filtros'));
      await tester.pumpAndSettle();
      expect(current.state.filtered, isFalse);
      await _scrollTo(tester, find.text('Todos los tipos'));
      expect(find.text('Todos los tipos'), findsOneWidget);
      expect(find.text('Todos los apuntes'), findsOneWidget);
      expect(find.text('zzz'), findsNothing);
    });

    testWidgets('a 320 px y con el texto al 200 % no se desborda', (
      tester,
    ) async {
      await pump(tester, width: 320, textScale: 2);
      expect(tester.takeException(), isNull);
      await _scrollTo(tester, find.text('¿Cuáles agregan filas?'));
      await tester.tap(find.text('¿Cuáles agregan filas?'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      // Sin sitio para las dos, «No lo sé» baja debajo de «Comprobar».
      final check = tester.getTopLeft(find.text('Comprobar'));
      final dontKnow = tester.getTopLeft(find.text('No lo sé'));
      expect(dontKnow.dy, greaterThan(check.dy));
    });

    testWidgets('a 320 px y al 200 %, los desplegables van uno debajo del otro '
        'y su menú se lee entero', (tester) async {
      await pump(tester, width: 320, textScale: 2);
      await _scrollTo(tester, find.text('Todos los tipos'));
      final type = tester.getTopLeft(find.text('Todos los tipos'));
      await _scrollTo(tester, find.text('Todos los apuntes'));
      final material = tester.getTopLeft(find.text('Todos los apuntes'));
      expect(material.dy, greaterThan(type.dy));
      await tester.tap(find.text('Todos los apuntes'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Límites'), findsWidgets);
    });

    testWidgets('tamaño táctil, etiquetas y contraste', (tester) async {
      final semantics = tester.ensureSemantics();
      await pump(tester, theme: AppTheme.dark);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      semantics.dispose();
    });
  });

  testWidgets('QuestionAnswerBar: con sitio, «No lo sé» y la principal en '
      'fila', (tester) async {
    tester.view.physicalSize = const Size(600, 300);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('es'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: QuestionAnswerBar(
            questionId: 'q1',
            primaryLabel: 'Comprobar',
            onPrimary: () {},
            onDontKnow: () {},
          ),
        ),
      ),
    );
    final check = tester.getTopLeft(find.text('Comprobar'));
    final dontKnow = tester.getTopLeft(find.text('No lo sé'));
    expect(dontKnow.dy, closeTo(check.dy, 4));
    expect(dontKnow.dx, lessThan(check.dx));
  });

  testWidgets('QuestionAnswerBar: al corregirse, el foco pasa a «Siguiente» '
      'en el mismo hueco (WCAG 2.4.3)', (tester) async {
    var answered = false;
    late StateSetter rebuild;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('es'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return QuestionAnswerBar(
                questionId: 'q1',
                answered: answered,
                primaryLabel: answered ? 'Siguiente' : 'Comprobar',
                onPrimary: () {},
                onDontKnow: () {},
              );
            },
          ),
        ),
      ),
    );
    Focus.of(tester.element(find.text('No lo sé'))).requestFocus();
    await tester.pump();
    rebuild(() => answered = true);
    await tester.pump();
    await tester.pump();
    expect(find.text('No lo sé'), findsNothing);
    expect(
      Focus.of(tester.element(find.text('Siguiente'))).hasPrimaryFocus,
      isTrue,
    );
  });

  group('simulacro', () {
    late _Start start;
    late _Complete complete;

    setUp(() {
      start = _Start();
      complete = _Complete();
      getIt.registerFactory<MockExamBloc>(
        () => MockExamBloc(
          getActive: _GetActive(),
          start: start,
          answer: _AnswerInSession(),
          complete: complete,
          getAccount: _GetAccount(),
        ),
      );
    });
    tearDown(() => getIt.unregister<MockExamBloc>());

    Future<void> pumpExam(WidgetTester tester) async {
      tester.view.physicalSize = const Size(420, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('es'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const MockExamPage(materialId: 'm1'),
        ),
      );
      await tester.pump();
      await tester.pump();
    }

    testWidgets('sin respuestas, el diálogo (lo dice el servidor) destaca '
        '«Seguir contestando» y, si se entrega, «Este simulacro no cuenta»', (
      tester,
    ) async {
      when(
        () => start(['m1'], questionCount: any(named: 'questionCount')),
      ).thenAnswer((_) async => Success(session.copyWith(countsIfSubmitted: false)));
      when(() => complete('t1')).thenAnswer(
        (_) async => Success(
          session.copyWith(
            status: TestSessionStatus.abandoned,
            counted: false,
            countsIfSubmitted: false,
          ),
        ),
      );
      // El cronómetro del simulacro no deja asentarse la pantalla: se avanza a
      // mano.
      Future<void> frames() async {
        for (var i = 0; i < 6; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
      }

      await pumpExam(tester);
      await tester.scrollUntilVisible(
        find.text('Entregar'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await frames();
      await tester.tap(find.text('Entregar'));
      await frames();
      expect(find.text('No has contestado ninguna'), findsOneWidget);
      expect(_filled('Seguir contestando'), findsOneWidget);
      await tester.tap(find.text('Entregar igualmente'));
      await frames();
      expect(find.text('Este simulacro no cuenta'), findsOneWidget);
    });
  });
}
