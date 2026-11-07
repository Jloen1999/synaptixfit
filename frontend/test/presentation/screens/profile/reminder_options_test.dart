import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/profile/notification_preferences.dart';
import 'package:synaptixfit/domain/models/reminders/reminder_options.dart';
import 'package:synaptixfit/domain/models/result/app_result.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/use_cases/reminders/change_reminder_options_use_case.dart';
import 'package:synaptixfit/domain/use_cases/reminders/get_reminder_options_use_case.dart';
import 'package:synaptixfit/presentation/l10n/gen_l10n/app_localizations.dart';
import 'package:synaptixfit/presentation/screens/profile/reminder_options/bloc/reminder_options_bloc.dart';
import 'package:synaptixfit/presentation/screens/profile/reminder_options/page/reminder_options_section.dart';
import 'package:synaptixfit/presentation/theme/app_theme.dart';

class _Get extends Mock implements GetReminderOptionsUseCaseContract {}

class _Change extends Mock implements ChangeReminderOptionsUseCaseContract {}

class _MockBloc extends MockBloc<ReminderOptionsEvent, ReminderOptionsState>
    implements ReminderOptionsBloc {}

/// «Más avisos» (ADR 0035): opciones cerradas y guardado al momento con sus
/// cuatro estados (carga, error con reintento, guardando y guardado).
void main() {
  const loaded = ReminderOptions();

  group('ReminderOptionsBloc', () {
    late _Get get;
    late _Change change;

    setUpAll(() => registerFallbackValue(loaded));

    setUp(() {
      get = _Get();
      change = _Change();
      when(() => get()).thenAnswer((_) async => const Success(loaded));
    });

    ReminderOptionsBloc build() =>
        ReminderOptionsBloc(get: get, change: change);

    const thirty = ReminderOptions(eventLeadMinutes: 30);

    blocTest<ReminderOptionsBloc, ReminderOptionsState>(
      'cada cambio pasa por «guardando» y queda «guardado»',
      setUp: () => when(
        () => change(thirty),
      ).thenAnswer((_) async => const Success(thirty)),
      build: build,
      act: (bloc) async {
        bloc.add(const ReminderOptionsEvent.started());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const ReminderOptionsEvent.changed(thirty));
      },
      expect: () => const [
        ReminderOptionsState(),
        ReminderOptionsState(loading: false),
        ReminderOptionsState(loading: false, options: thirty, saving: true),
        ReminderOptionsState(loading: false, options: thirty, saved: true),
      ],
    );

    blocTest<ReminderOptionsBloc, ReminderOptionsState>(
      'si el servidor lo rechaza, vuelve a lo guardado y dice por qué',
      setUp: () => when(() => change(thirty)).thenAnswer(
        (_) async =>
            const Failure(AppError.business('REMINDER_OPTIONS_INVALID')),
      ),
      build: build,
      act: (bloc) async {
        bloc.add(const ReminderOptionsEvent.started());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const ReminderOptionsEvent.changed(thirty));
      },
      skip: 3,
      expect: () => const [
        ReminderOptionsState(
          loading: false,
          saveError: AppError.business('REMINDER_OPTIONS_INVALID'),
          unsaved: thirty,
        ),
      ],
    );

    blocTest<ReminderOptionsBloc, ReminderOptionsState>(
      'tocar la opción ya elegida no guarda nada',
      build: build,
      seed: () => const ReminderOptionsState(loading: false),
      act: (bloc) => bloc.add(const ReminderOptionsEvent.changed(loaded)),
      expect: () => const <ReminderOptionsState>[],
      verify: (_) => verifyNever(() => change(any())),
    );

    test('los guardados van en fila y gana el último', () async {
      const sixty = ReminderOptions(eventLeadMinutes: 60);
      final first = Completer<AppResult<ReminderOptions>>();
      when(() => change(thirty)).thenAnswer((_) => first.future);
      when(() => change(sixty)).thenAnswer((_) async => const Success(sixty));
      final bloc = build()..add(const ReminderOptionsEvent.started());
      await Future<void>.delayed(Duration.zero);

      bloc.add(const ReminderOptionsEvent.changed(thirty));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const ReminderOptionsEvent.changed(sixty));
      await Future<void>.delayed(Duration.zero);
      // El segundo espera a que el servidor responda al primero.
      verifyNever(() => change(sixty));

      first.complete(const Success(thirty));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      verifyInOrder([() => change(thirty), () => change(sixty)]);
      expect(
        bloc.state,
        const ReminderOptionsState(loading: false, options: sixty, saved: true),
      );
      await bloc.close();
    });

    blocTest<ReminderOptionsBloc, ReminderOptionsState>(
      'no deja entregas y exámenes sin ningún día',
      build: build,
      seed: () => const ReminderOptionsState(loading: false),
      act: (bloc) => bloc.add(
        const ReminderOptionsEvent.changed(
          ReminderOptions(deadlineDaysBefore: []),
        ),
      ),
      expect: () => const <ReminderOptionsState>[],
      verify: (_) => verifyNever(() => change(any())),
    );

    blocTest<ReminderOptionsBloc, ReminderOptionsState>(
      'si no carga, enseña el error para reintentar',
      setUp: () => when(
        () => get(),
      ).thenAnswer((_) async => const Failure(AppError.network())),
      build: build,
      act: (bloc) => bloc.add(const ReminderOptionsEvent.started()),
      expect: () => const [
        ReminderOptionsState(),
        ReminderOptionsState(loading: false, error: AppError.network()),
      ],
    );
  });

  group('ReminderOptionsView', () {
    late _MockBloc bloc;

    setUpAll(() => registerFallbackValue(const ReminderOptionsEvent.started()));

    setUp(() => bloc = _MockBloc());

    Future<void> pump(
      WidgetTester tester, {
      double textScale = 1,
      Locale locale = const Locale('es'),
    }) async {
      tester.view.physicalSize = Size(360, 2600 * textScale);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          locale: locale,
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
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: BlocProviderValue(bloc: bloc),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('enseña las opciones cerradas y cambia la antelación', (
      tester,
    ) async {
      when(
        () => bloc.state,
      ).thenReturn(const ReminderOptionsState(loading: false));
      await pump(tester);

      expect(find.text('Eventos y clases'), findsOneWidget);
      expect(find.text('Entregas y exámenes'), findsOneWidget);
      expect(find.text('Tareas de reto'), findsOneWidget);
      expect(find.text('Resumen de la mañana'), findsOneWidget);
      for (final m in [5, 15, 30]) {
        expect(find.text('$m min antes'), findsOneWidget);
      }
      expect(find.text('1 h antes'), findsOneWidget);
      // La opción ya elegida no vuelve a guardarse.
      await tester.tap(find.text('15 min antes'));
      verifyNever(() => bloc.add(any()));
      await tester.tap(find.text('30 min antes'));
      verify(
        () => bloc.add(
          const ReminderOptionsEvent.changed(
            ReminderOptions(eventLeadMinutes: 30),
          ),
        ),
      ).called(1);
    });

    testWidgets(
      'no deja quitar el último día de las entregas y explica por qué',
      (tester) async {
        when(() => bloc.state).thenReturn(
          const ReminderOptionsState(
            loading: false,
            options: ReminderOptions(deadlineDaysBefore: [3]),
          ),
        );
        await pump(tester);

        const why =
            'Deja al menos un día marcado: así no se te pasa ninguna entrega '
            'ni ningún examen.';
        expect(find.text(why), findsOneWidget);
        await tester.tap(find.text('3 días antes'));
        verifyNever(() => bloc.add(any()));

        await tester.tap(find.text('7 días antes'));
        verify(
          () => bloc.add(
            const ReminderOptionsEvent.changed(
              ReminderOptions(deadlineDaysBefore: [3, 7]),
            ),
          ),
        ).called(1);
      },
    );

    testWidgets('dice «Guardando…» y después «Guardado»', (tester) async {
      final states = StreamController<ReminderOptionsState>();
      addTearDown(states.close);
      whenListen(
        bloc,
        states.stream,
        initialState: const ReminderOptionsState(loading: false, saving: true),
      );
      await pump(tester);
      expect(find.text('Guardando…'), findsOneWidget);

      states.add(const ReminderOptionsState(loading: false, saved: true));
      // Un ciclo para entregar el estado y otro para pintarlo.
      await tester.pump();
      await tester.pump();
      expect(find.text('Guardado'), findsOneWidget);
    });

    testWidgets('si no se guarda, lo dice y deja reintentarlo', (tester) async {
      const thirty = ReminderOptions(eventLeadMinutes: 30);
      final states = StreamController<ReminderOptionsState>();
      addTearDown(states.close);
      whenListen(
        bloc,
        states.stream,
        initialState: const ReminderOptionsState(loading: false, saving: true),
      );
      await pump(tester);
      states.add(
        const ReminderOptionsState(
          loading: false,
          saveError: AppError.network(),
          unsaved: thirty,
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(
        find.text('No se pudo guardar el cambio y se ha quedado como estaba.'),
        findsOneWidget,
      );
      // Espera a que el aviso termine de entrar.
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.text('Reintentar'));
      verify(
        () => bloc.add(const ReminderOptionsEvent.changed(thirty)),
      ).called(1);
    });

    testWidgets('si no carga, ofrece reintentar', (tester) async {
      when(() => bloc.state).thenReturn(
        const ReminderOptionsState(loading: false, error: AppError.network()),
      );
      await pump(tester);
      await tester.tap(find.text('Reintentar'));
      verify(() => bloc.add(const ReminderOptionsEvent.started())).called(1);
    });

    testWidgets('cumple las guías de accesibilidad', (tester) async {
      final handle = tester.ensureSemantics();
      when(
        () => bloc.state,
      ).thenReturn(const ReminderOptionsState(loading: false));
      await pump(tester);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });

    testWidgets('se ve entera con texto al 200 %', (tester) async {
      when(() => bloc.state).thenReturn(
        const ReminderOptionsState(
          loading: false,
          options: ReminderOptions(deadlineDaysBefore: [1]),
        ),
      );
      await pump(tester, textScale: 2);
      expect(tester.takeException(), isNull);
      expect(
        find.text('Resumen de la mañana', skipOffstage: false),
        findsOneWidget,
      );
    });

    testWidgets('en francés, al 200 %, la cabecera y los chips caben', (
      tester,
    ) async {
      when(
        () => bloc.state,
      ).thenReturn(const ReminderOptionsState(loading: false, saved: true));
      await pump(tester, textScale: 2, locale: const Locale('fr'));
      expect(tester.takeException(), isNull);
      expect(find.text('Autres rappels', skipOffstage: false), findsOneWidget);
    });

    testWidgets('elegir la hora del resumen no quita el foco', (tester) async {
      const halfPastSeven = ReminderOptions(
        morningSummaryAt: ClockTime(hour: 7, minute: 30),
      );
      final states = StreamController<ReminderOptionsState>();
      addTearDown(states.close);
      whenListen(
        bloc,
        states.stream,
        initialState: const ReminderOptionsState(loading: false),
      );
      await pump(tester);
      final field = find.byType(DropdownButton<ClockTime>);
      final before = tester.element(field);
      await tester.tap(field);
      await tester.pumpAndSettle();
      // Formato de hora del español (H:mm).
      await tester.tap(find.text('7:30').last);
      await tester.pumpAndSettle();
      verify(
        () => bloc.add(const ReminderOptionsEvent.changed(halfPastSeven)),
      ).called(1);
      states.add(
        const ReminderOptionsState(loading: false, options: halfPastSeven),
      );
      await tester.pump();
      await tester.pump();
      // Con la hora nueva sigue el mismo control (no se recrea y no pierde
      // el foco).
      expect(tester.element(field), same(before));
    });
  });
}

/// Monta la vista sobre el bloc de prueba.
class BlocProviderValue extends StatelessWidget {
  const BlocProviderValue({super.key, required this.bloc});

  final ReminderOptionsBloc bloc;

  @override
  Widget build(BuildContext context) => BlocProvider<ReminderOptionsBloc>.value(
    value: bloc,
    child: const ReminderOptionsView(deviceRemindersOn: true),
  );
}
