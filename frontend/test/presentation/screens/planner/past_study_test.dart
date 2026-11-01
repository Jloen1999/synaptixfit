import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/planner/calendar_block.dart';
import 'package:synaptixfit/domain/models/planner/planner_options.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/use_cases/account/get_account_use_case.dart';
import 'package:synaptixfit/domain/use_cases/planner/get_planner_subjects_use_case.dart';
import 'package:synaptixfit/domain/use_cases/planner/log_past_study_use_case.dart';
import 'package:synaptixfit/presentation/l10n/gen_l10n/app_localizations.dart';
import 'package:synaptixfit/presentation/screens/planner/past_study/bloc/past_study_bloc.dart';
import 'package:synaptixfit/presentation/screens/planner/past_study/page/past_study_page.dart';
import 'package:synaptixfit/presentation/theme/app_theme.dart';

import 'planner_fixtures.dart';

class _Log extends Mock implements LogPastStudyUseCaseContract {}

class _Subjects extends Mock implements GetPlannerSubjectsUseCaseContract {}

class _Account extends Mock implements GetAccountUseCaseContract {}

class _MockBloc extends MockBloc<PastStudyEvent, PastStudyState>
    implements PastStudyBloc {}

/// «Apuntar estudio hecho»: carga asignaturas, envía el rato ya terminado y
/// avisa sin mandar nada si aún no ha terminado.
void main() {
  late _Log log;
  late _Subjects subjects;
  late _Account account;
  final start = DateTime(2026, 11, 1, 17);

  setUpAll(() {
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(const PastStudyEvent.started());
  });

  setUp(() {
    log = _Log();
    subjects = _Subjects();
    account = _Account();
    when(() => subjects()).thenAnswer(
      (_) async => const Success([SubjectOption(id: 's1', name: 'Cálculo')]),
    );
    when(() => account()).thenAnswer((_) async => const Success(testAccount));
  });

  PastStudyBloc build() => PastStudyBloc(
    logPastStudy: log,
    getSubjects: subjects,
    getAccount: account,
  );

  blocTest<PastStudyBloc, PastStudyState>(
    'carga las asignaturas para elegir',
    build: build,
    act: (bloc) => bloc.add(const PastStudyEvent.started()),
    expect: () => [
      const PastStudyState(loadingSubjects: true),
      const PastStudyState(
        subjects: [SubjectOption(id: 's1', name: 'Cálculo')],
      ),
    ],
  );

  blocTest<PastStudyBloc, PastStudyState>(
    'guarda el estudio con su asignatura y refresca la cuenta si da XP',
    setUp: () =>
        when(
          () =>
              log(start: start, minutes: 90, subjectId: 's1', title: 'Tema 3'),
        ).thenAnswer(
          (_) async => Success(BlockCompletion(block: block(), xpDelta: 30)),
        ),
    build: build,
    act: (bloc) => bloc.add(
      PastStudyEvent.submitted(
        start: start,
        minutes: 90,
        subjectId: 's1',
        title: 'Tema 3',
      ),
    ),
    expect: () => [
      const PastStudyState(submitting: true),
      const PastStudyState(savedXp: 30, updatedAccount: testAccount),
    ],
  );

  blocTest<PastStudyBloc, PastStudyState>(
    'si el servidor lo rechaza, enseña el error',
    setUp: () =>
        when(
          () => log(
            start: any(named: 'start'),
            minutes: any(named: 'minutes'),
            subjectId: any(named: 'subjectId'),
            title: any(named: 'title'),
          ),
        ).thenAnswer(
          (_) async => const Failure(
            AppError.business('PLANNER_PAST_ACTIVITY_OUT_OF_RANGE'),
          ),
        ),
    build: build,
    act: (bloc) =>
        bloc.add(PastStudyEvent.submitted(start: start, minutes: 60)),
    skip: 1,
    expect: () => [
      const PastStudyState(
        error: AppError.business('PLANNER_PAST_ACTIVITY_OUT_OF_RANGE'),
      ),
    ],
  );

  testWidgets('si aún no ha terminado, avisa y no envía nada', (tester) async {
    final bloc = _MockBloc();
    when(() => bloc.state).thenReturn(
      const PastStudyState(
        subjects: [SubjectOption(id: 's1', name: 'Cálculo')],
      ),
    );
    tester.view.physicalSize = const Size(320, 1400);
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
        home: BlocProvider<PastStudyBloc>.value(
          value: bloc,
          // A las 8:00 la hora por defecto es 6:00 y 5 h de estudio acaban a
          // las 11:00: aún no ha terminado.
          child: PastStudyView(now: () => DateTime(2026, 11, 2, 8)),
        ),
      ),
    );
    // De 60 a 300 minutos (5 h), de 15 en 15.
    for (var i = 0; i < 16; i++) {
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pump();
    }
    await tester.ensureVisible(find.text('Guardar como hecho'));
    await tester.tap(find.text('Guardar como hecho'));
    await tester.pump();

    expect(find.textContaining('aún no ha terminado'), findsOneWidget);
    verifyNever(() => bloc.add(any(that: isA<PastStudySubmitted>())));
  });
}
