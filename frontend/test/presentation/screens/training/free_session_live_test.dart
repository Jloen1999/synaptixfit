import 'package:bloc_test/bloc_test.dart';
import 'package:synaptixfit/domain/enums/training_enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/app/di/app_di.dart';
import 'package:synaptixfit/domain/models/result/app_result.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/models/social/together.dart';
import 'package:synaptixfit/domain/use_cases/social/together/find_workout_together_by_session_use_case.dart';
import 'package:synaptixfit/presentation/l10n/gen_l10n/app_localizations.dart';
import 'package:synaptixfit/presentation/screens/social/together/live/bloc/workout_together_live_bloc.dart';
import 'package:synaptixfit/presentation/screens/training/live_session/bloc/live_session_bloc.dart';
import 'package:synaptixfit/presentation/screens/training/live_session/page/live_session_page.dart';
import 'package:synaptixfit/presentation/theme/app_theme.dart';

import 'training_fixtures.dart';

/// Sesión libre con ejercicios en vivo (ADR 0067): «Añadir ejercicio» a la
/// vista y, sin ejercicios, un estado vacío con una sola acción.
class _MockLiveBloc extends MockBloc<LiveSessionEvent, LiveSessionState>
    implements LiveSessionBloc {}

class _NotTogether implements FindWorkoutTogetherBySessionUseCaseContract {
  @override
  Future<AppResult<WorkoutTogether?>> call(String sessionId) async =>
      const Success(null);
}

void main() {
  setUpAll(() => initializeDateFormatting('es'));
  late _MockLiveBloc bloc;

  setUp(() {
    bloc = _MockLiveBloc();
    getIt
      ..registerFactory<LiveSessionBloc>(() => bloc)
      ..registerFactory<WorkoutTogetherLiveBloc>(
        () => WorkoutTogetherLiveBloc(find: _NotTogether()),
      );
  });

  tearDown(() {
    getIt
      ..unregister<LiveSessionBloc>()
      ..unregister<WorkoutTogetherLiveBloc>();
  });

  Future<void> pump(
    WidgetTester tester, {
    double width = 360,
    double height = 800,
    double textScale = 1,
    bool reduceMotion = false,
  }) async {
    tester.view.physicalSize = Size(width, height);
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
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: reduceMotion,
          ),
          child: child!,
        ),
        home: const LiveSessionPage(sessionId: 's1'),
      ),
    );
    await tester.pump();
  }

  final free = TrainingFixtures.session().copyWith(
    routineId: null,
    dayId: null,
    type: SessionType.free,
  );

  testWidgets(
    'sin ejercicios: «Añade tu primer ejercicio», sin series libres',
    (tester) async {
      when(() => bloc.state).thenReturn(
        LiveSessionState(
          status: LiveStatus.ready,
          sessionId: 's1',
          session: free,
        ),
      );
      await pump(tester, width: 320, textScale: 2);
      expect(tester.takeException(), isNull);
      expect(find.text('Añade tu primer ejercicio'), findsOneWidget);
      expect(
        find.widgetWithText(FilledButton, 'Añadir ejercicio'),
        findsOneWidget,
      );
      expect(find.text('Series libres'), findsNothing);
      expect(find.text('Sesión libre'), findsOneWidget);
    },
  );

  testWidgets('con ejercicios: la tabla de siempre y «Añadir ejercicio»', (
    tester,
  ) async {
    final exercises = [TrainingFixtures.planned('f1')];
    when(() => bloc.state).thenReturn(
      LiveSessionState(
        status: LiveStatus.ready,
        sessionId: 's1',
        session: free.copyWith(exercises: exercises),
        exercises: exercises,
        activeExerciseId: 'f1',
      ),
    );
    final semantics = tester.ensureSemantics();
    await pump(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('Añadir ejercicio'), findsOneWidget);
    expect(find.text('Ejercicio f1'), findsWidgets);
    expect(find.text('Series libres'), findsNothing);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    semantics.dispose();
  });
}
