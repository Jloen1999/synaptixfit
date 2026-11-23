import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:synaptixfit/app/di/app_di.dart';
import 'package:synaptixfit/domain/enums/data_topic.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/result/app_result.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/models/training/health_consent.dart';
import 'package:synaptixfit/domain/models/training/today_adaptation.dart';
import 'package:synaptixfit/domain/models/training/training_page.dart';
import 'package:synaptixfit/domain/models/training/wellbeing.dart';
import 'package:synaptixfit/domain/models/account/account.dart';
import 'package:synaptixfit/domain/use_cases/account/get_account_use_case.dart';
import 'package:synaptixfit/domain/use_cases/sync/watch_data_changes_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/get_check_ins_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/get_health_consent_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/get_today_adaptation_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/get_today_check_in_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/give_health_consent_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/submit_check_in_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/submit_quick_check_in_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/withdraw_health_consent_use_case.dart';
import 'package:synaptixfit/presentation/l10n/gen_l10n/app_localizations.dart';
import 'package:synaptixfit/presentation/screens/training/check_in/bloc/check_in_bloc.dart';
import 'package:synaptixfit/presentation/screens/training/check_in/page/check_in_page.dart';
import 'package:synaptixfit/presentation/screens/training/health_consent/bloc/health_consent_bloc.dart';
import 'package:synaptixfit/presentation/screens/training/quick_check_in/bloc/quick_check_in_bloc.dart';
import 'package:synaptixfit/presentation/screens/training/quick_check_in/page/quick_check_in_card.dart';
import 'package:synaptixfit/presentation/theme/app_theme.dart';
import 'package:synaptixfit/presentation/widgets/widgets.dart';

/// «¿Qué tal estás hoy?», tanda 4 (ADR 0062): tras guardar, una confirmación
/// que se queda en la tarjeta («Guardado hoy a las 9:41», con icono), dicha al
/// lector una vez; si falla, el motivo y «Reintentar» en la propia tarjeta.

final _savedAt = DateTime(2026, 11, 21, 9, 41);

/// Servidor de mentira del registro diario: guarda (o falla si [offline]).
class _Server {
  bool offline = false;
  bool done = false;
  int submits = 0;

  /// La lectura de la adaptación de hoy falla (sin conexión).
  bool adaptationFails = false;
}

class _Adaptation implements GetTodayAdaptationUseCaseContract {
  _Adaptation(this.server);
  final _Server server;
  @override
  Future<AppResult<TodayAdaptation>> call() async => server.adaptationFails
      ? const Failure(AppError.network())
      : Success(
          server.done
              ? const TodayAdaptation(
                  checkInDone: true,
                  sleepQuality: 4,
                  energy: 4,
                  soreness: 2,
                )
              : const TodayAdaptation(),
        );
}

class _SubmitQuick implements SubmitQuickCheckInUseCaseContract {
  _SubmitQuick(this.server);
  final _Server server;
  @override
  Future<AppResult<Unit>> call(QuickCheckIn input) async {
    server.submits++;
    if (server.offline) return const Failure(AppError.network());
    server.done = true;
    return const Success(unit);
  }
}

CheckIn _checkIn(CheckInInput input) => CheckIn(
  id: 'c1',
  date: DateTime(2026, 11, 21),
  sleepQuality: input.sleepQuality,
  stress: input.stress,
  energy: input.energy,
  soreness: input.soreness,
  readyToTrain: true,
  fatigueScore: 20,
  requiresAdaptation: false,
);

class _Today implements GetTodayCheckInUseCaseContract {
  @override
  Future<AppResult<CheckIn?>> call() async => const Success(null);
}

class _History implements GetCheckInsUseCaseContract {
  @override
  Future<AppResult<TrainingPage<CheckIn>>> call({
    int page = 0,
    int size = 20,
  }) async => const Success(
    TrainingPage<CheckIn>(items: [], page: 0, totalPages: 0, totalItems: 0),
  );
}

class _Submit implements SubmitCheckInUseCaseContract {
  _Submit(this.server);
  final _Server server;
  @override
  Future<AppResult<CheckInResult>> call(CheckInInput input) async {
    server.submits++;
    if (server.offline) return const Failure(AppError.network());
    return Success(
      CheckInResult(checkIn: _checkIn(input), firstOfDay: false, xpAwarded: 0),
    );
  }
}

class _Account implements GetAccountUseCaseContract {
  @override
  Future<AppResult<Account>> call() async => const Failure(AppError.network());
}

class _NoDataChanges implements WatchDataChangesUseCaseContract {
  @override
  Stream<Set<DataTopic>> call({required Set<DataTopic> topics}) =>
      const Stream.empty();
}

/// El permiso de datos de salud ya está dado: se guarda sin hoja.
class _ConsentGiven implements GetHealthConsentUseCaseContract {
  @override
  Future<AppResult<HealthConsent>> call() async =>
      const Success(HealthConsent(given: true));
}

class _Give implements GiveHealthConsentUseCaseContract {
  @override
  Future<AppResult<Unit>> call() async => const Success(unit);
}

class _Withdraw implements WithdrawHealthConsentUseCaseContract {
  @override
  Future<AppResult<Unit>> call({required bool deleteRecords}) async =>
      const Success(unit);
}

void main() {
  late _Server server;
  final l10n = lookupAppLocalizations(const Locale('es'));

  setUpAll(() => initializeDateFormatting('es'));

  setUp(() {
    server = _Server();
    getIt
      ..registerFactory<HealthConsentBloc>(
        () => HealthConsentBloc(
          get: _ConsentGiven(),
          give: _Give(),
          withdraw: _Withdraw(),
        ),
      )
      ..registerFactory<QuickCheckInBloc>(
        () => QuickCheckInBloc(
          getAdaptation: _Adaptation(server),
          submit: _SubmitQuick(server),
          watchDataChanges: _NoDataChanges(),
          clock: () => _savedAt,
        ),
      )
      ..registerFactory<CheckInBloc>(
        () => CheckInBloc(
          getToday: _Today(),
          getHistory: _History(),
          submit: _Submit(server),
          getAccount: _Account(),
          clock: () => _savedAt,
        ),
      );
  });

  tearDown(() {
    getIt
      ..unregister<HealthConsentBloc>()
      ..unregister<QuickCheckInBloc>()
      ..unregister<CheckInBloc>();
  });

  final savedText = 'Guardado hoy a las ${DateFormat.Hm().format(_savedAt)}';

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    double width = 360,
    double textScale = 1,
  }) async {
    tester.view.physicalSize = Size(width, 900);
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
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: child,
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Contesta las tres preguntas con la respuesta de la derecha (la mejor).
  Future<void> answerAll(WidgetTester tester) async {
    for (final (i, word) in [
      l10n.trainingQuickGood,
      l10n.trainingQuickHigh,
      l10n.trainingQuickSoreNone,
    ].indexed) {
      final option = find.descendant(
        of: find.byType(AppSegmentedChoice<int>).at(i),
        matching: find.text(word),
      );
      await tester.ensureVisible(option);
      await tester.tap(option);
      await tester.pumpAndSettle();
    }
  }

  const card = Scaffold(body: SingleChildScrollView(child: QuickCheckInCard()));

  Future<void> openCard(WidgetTester tester) async {
    await tester.tap(find.text(l10n.trainingQuickCheckInTitle));
    await tester.pumpAndSettle();
  }

  List<String> announcements(WidgetTester tester) => [
    for (final a in tester.takeAnnouncements()) a.message,
  ];

  group('tarjeta de Gimnasio', () {
    testWidgets('con la tercera respuesta guarda y deja «Guardado hoy a las…» '
        'con icono, anunciado una vez', (tester) async {
      final semantics = tester.ensureSemantics();
      await pump(tester, card);
      await openCard(tester);
      await answerAll(tester);

      expect(server.submits, 1);
      expect(find.text(savedText), findsOneWidget);
      // Icono y texto: el color no es la única señal.
      expect(
        find.descendant(
          of: find.byType(AppInlineMessage),
          matching: find.byIcon(Icons.check_circle_outline_rounded),
        ),
        findsOneWidget,
      );
      expect(announcements(tester), [
        '$savedText. ${l10n.trainingQuickAllGood}',
      ]);
      // Se queda: no es un aviso que se va solo.
      await tester.pump(const Duration(seconds: 10));
      expect(find.text(savedText), findsOneWidget);
      expect(announcements(tester), isEmpty);
      semantics.dispose();
    });

    testWidgets('si falla, el motivo y «Reintentar» en la tarjeta; al '
        'reintentar, guardado', (tester) async {
      final semantics = tester.ensureSemantics();
      server.offline = true;
      await pump(tester, card);
      await openCard(tester);
      await answerAll(tester);

      expect(find.text(l10n.errorNetwork), findsOneWidget);
      expect(find.text(savedText), findsNothing);
      expect(announcements(tester), isEmpty);

      server.offline = false;
      await tester.tap(find.text(l10n.commonRetry));
      await tester.pumpAndSettle();
      expect(server.submits, 2);
      expect(find.text(l10n.errorNetwork), findsNothing);
      expect(find.text(savedText), findsOneWidget);
      expect(announcements(tester), hasLength(1));
      semantics.dispose();
    });

    testWidgets('al cambiar, «Guardar cambios» se vuelve «Reintentar» si '
        'falla', (tester) async {
      server.done = true;
      await pump(tester, card);
      await tester.tap(find.text(l10n.trainingQuickChange));
      await tester.pumpAndSettle();
      server.offline = true;
      await tester.tap(find.text(l10n.trainingCheckInUpdateAction));
      await tester.pumpAndSettle();
      expect(find.text(l10n.errorNetwork), findsOneWidget);
      expect(find.text(l10n.commonRetry), findsOneWidget);
      expect(find.text(l10n.trainingCheckInUpdateAction), findsNothing);

      server.offline = false;
      await tester.tap(find.text(l10n.commonRetry));
      await tester.pumpAndSettle();
      expect(find.text(savedText), findsOneWidget);
    });

    testWidgets('si se guarda pero no se puede leer cómo queda el entreno, el '
        'registro cuenta igual y se ofrece «Reintentar» la lectura', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pump(tester, card);
      await openCard(tester);
      server.adaptationFails = true;
      await answerAll(tester);

      expect(server.submits, 1);
      // Hecho: ni preguntas vacías ni «Reintentar» desactivado.
      expect(find.byType(AppSegmentedChoice<int>), findsNothing);
      expect(find.text(savedText), findsOneWidget);
      expect(find.text(l10n.errorNetwork), findsOneWidget);
      final retry = find.widgetWithText(AppSecondaryButton, l10n.commonRetry);
      expect(tester.widget<AppSecondaryButton>(retry).onPressed, isNotNull);
      // Se anuncia el guardado, sin decir cómo queda un entreno que no se sabe.
      expect(announcements(tester), [savedText]);

      server.adaptationFails = false;
      await tester.tap(retry);
      await tester.pumpAndSettle();
      expect(server.submits, 1);
      expect(find.text(l10n.errorNetwork), findsNothing);
      expect(find.text(l10n.trainingQuickAllGood), findsOneWidget);
      expect(find.text(savedText), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('si falla la lectura al entrar, el motivo y «Reintentar» '
        'vuelven a leer', (tester) async {
      server.adaptationFails = true;
      await pump(tester, card);
      expect(find.text(l10n.errorNetwork), findsOneWidget);
      final retry = find.widgetWithText(AppSecondaryButton, l10n.commonRetry);
      expect(tester.widget<AppSecondaryButton>(retry).onPressed, isNotNull);

      server
        ..adaptationFails = false
        ..done = true;
      await tester.tap(retry);
      await tester.pumpAndSettle();
      expect(server.submits, 0);
      expect(find.text(l10n.errorNetwork), findsNothing);
      expect(find.text(l10n.trainingQuickAllGood), findsOneWidget);
    });

    testWidgets('320 px con texto al 200 %: la confirmación cabe', (
      tester,
    ) async {
      await pump(tester, card, width: 320, textScale: 2);
      await openCard(tester);
      await answerAll(tester);
      expect(tester.takeException(), isNull);
      expect(find.text(savedText), findsOneWidget);
    });
  });

  group('pantalla del registro', () {
    testWidgets('la tercera respuesta guarda: «Guardado hoy a las…» junto a '
        '«Guardar cambios», anunciado una vez', (tester) async {
      final semantics = tester.ensureSemantics();
      await pump(tester, const CheckInPage());
      await answerAll(tester);

      expect(server.submits, 1);
      expect(find.text(savedText), findsOneWidget);
      expect(find.text(l10n.trainingCheckInUpdateAction), findsOneWidget);
      // Un solo anuncio con lo que pasa después, sin aviso aparte.
      expect(announcements(tester), [
        '$savedText. ${l10n.trainingMsgCheckInSaved}',
      ]);
      expect(find.byType(SnackBar), findsNothing);
      // La tercera respuesta guardó: la nota va justo bajo las preguntas.
      expect(
        tester.getTopLeft(find.text(savedText)).dy,
        lessThan(tester.getTopLeft(find.text(l10n.trainingQuickFull)).dy),
      );

      // Cambiar algo después deja de estar guardado.
      final option = find.descendant(
        of: find.byType(AppSegmentedChoice<int>).first,
        matching: find.text(l10n.trainingQuickBad),
      );
      await tester.ensureVisible(option);
      await tester.tap(option);
      await tester.pumpAndSettle();
      expect(find.text(savedText), findsNothing);
      semantics.dispose();
    });

    testWidgets('si falla, el motivo y «Reintentar» a la vista', (
      tester,
    ) async {
      server.offline = true;
      await pump(tester, const CheckInPage());
      await answerAll(tester);
      expect(find.text(l10n.errorNetwork), findsOneWidget);
      final retry = find.text(l10n.commonRetry);
      expect(retry, findsOneWidget);

      server.offline = false;
      await tester.ensureVisible(retry);
      await tester.tap(retry);
      await tester.pumpAndSettle();
      expect(find.text(l10n.errorNetwork), findsNothing);
      expect(find.text(savedText), findsOneWidget);
    });

    testWidgets('320 px con texto al 200 %: guardado y error caben', (
      tester,
    ) async {
      server.offline = true;
      await pump(tester, const CheckInPage(), width: 320, textScale: 2);
      await answerAll(tester);
      expect(tester.takeException(), isNull);
      expect(find.text(l10n.errorNetwork), findsOneWidget);
      server.offline = false;
      final retry = find.text(l10n.commonRetry);
      await tester.ensureVisible(retry);
      await tester.tap(retry);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text(savedText), findsOneWidget);
    });
  });
}
