import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synaptixfit/app/di/app_di.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/result/app_result.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/models/training/health_consent.dart';
import 'package:synaptixfit/domain/use_cases/training/get_health_consent_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/give_health_consent_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/withdraw_health_consent_use_case.dart';
import 'package:synaptixfit/presentation/l10n/gen_l10n/app_localizations.dart';
import 'package:synaptixfit/presentation/screens/training/health_consent/bloc/health_consent_bloc.dart';
import 'package:synaptixfit/presentation/screens/training/health_consent/page/health_consent_sheet.dart';
import 'package:synaptixfit/presentation/theme/app_theme.dart';

/// Servidor de mentira del permiso de datos de salud (ADR 0034).
class _FakeConsent {
  bool given = false;
  bool offline = false;
  bool? deletedRecords;
}

class _Get implements GetHealthConsentUseCaseContract {
  _Get(this.fake);
  final _FakeConsent fake;
  @override
  Future<AppResult<HealthConsent>> call() async => fake.offline
      ? const Failure(AppError.network())
      : Success(HealthConsent(given: fake.given));
}

class _Give implements GiveHealthConsentUseCaseContract {
  _Give(this.fake);
  final _FakeConsent fake;
  @override
  Future<AppResult<Unit>> call() async {
    fake.given = true;
    return const Success(unit);
  }
}

class _Withdraw implements WithdrawHealthConsentUseCaseContract {
  _Withdraw(this.fake);
  final _FakeConsent fake;
  @override
  Future<AppResult<Unit>> call({required bool deleteRecords}) async {
    fake.given = false;
    fake.deletedRecords = deleteRecords;
    return const Success(unit);
  }
}

void main() {
  late _FakeConsent fake;

  HealthConsentBloc build() => HealthConsentBloc(
    get: _Get(fake),
    give: _Give(fake),
    withdraw: _Withdraw(fake),
  );

  setUp(() => fake = _FakeConsent());

  group('HealthConsentBloc', () {
    blocTest<HealthConsentBloc, HealthConsentState>(
      'lee si el permiso está dado',
      setUp: () => fake.given = true,
      build: build,
      act: (bloc) => bloc.add(const HealthConsentEvent.started()),
      verify: (bloc) => expect(bloc.state.given, isTrue),
    );

    blocTest<HealthConsentBloc, HealthConsentState>(
      'retirarlo con «borrar» lo pide así al servidor',
      setUp: () => fake.given = true,
      build: build,
      act: (bloc) => bloc
        ..add(const HealthConsentEvent.started())
        ..add(const HealthConsentEvent.withdrawn(deleteRecords: true)),
      wait: const Duration(milliseconds: 10),
      verify: (bloc) {
        expect(bloc.state.given, isFalse);
        expect(bloc.state.withdrawals, 1);
        expect(fake.deletedRecords, isTrue);
      },
    );
  });

  group('Antes del registro diario', () {
    bool? result;

    setUp(() {
      result = null;
      getIt.registerFactory<HealthConsentBloc>(build);
    });

    tearDown(() => getIt.unregister<HealthConsentBloc>());

    Future<void> pump(WidgetTester tester, {ThemeData? theme}) async {
      tester.view.physicalSize = const Size(400, 1600);
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
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async =>
                    result = await ensureHealthConsent(context),
                child: const Text('Guardar'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
    }

    testWidgets('con el permiso ya dado no enseña nada y sigue', (
      tester,
    ) async {
      fake.given = true;
      await pump(tester);
      expect(result, isTrue);
      expect(find.byType(HealthConsentSheet), findsNothing);
    });

    testWidgets('sin permiso explica para qué y exige marcar la casilla', (
      tester,
    ) async {
      await pump(tester);
      expect(find.byType(HealthConsentSheet), findsOneWidget);
      await tester.tap(find.text('Dar permiso y seguir'));
      await tester.pump();
      expect(find.text('Marca la casilla para dar tu permiso.'), findsOneWidget);
      expect(fake.given, isFalse);

      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();
      await tester.tap(find.text('Dar permiso y seguir'));
      await tester.pumpAndSettle();
      expect(fake.given, isTrue);
      expect(result, isTrue);
    });

    testWidgets('«Ahora no» no guarda nada', (tester) async {
      await pump(tester);
      await tester.tap(find.text('Ahora no'));
      await tester.pumpAndSettle();
      expect(result, isFalse);
      expect(fake.given, isFalse);
    });

    testWidgets('sin conexión deja intentarlo (el servidor lo comprobará)', (
      tester,
    ) async {
      fake.offline = true;
      await pump(tester);
      expect(result, isTrue);
    });

    for (final (name, theme) in [
      ('claro', AppTheme.light),
      ('oscuro', AppTheme.dark),
    ]) {
      testWidgets('accesibilidad de la hoja, tema $name', (tester) async {
        final semantics = tester.ensureSemantics();
        await pump(tester, theme: theme);
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        // La guía de contraste de Flutter mide píxeles con la fuente de test y en
        // el tema claro da falsos fallos con colores del tema que cumplen AA
        // (7,5:1); el contraste real de los tokens lo prueba contrast_test.
        if (theme == AppTheme.dark) {
          await expectLater(tester, meetsGuideline(textContrastGuideline));
        }
        semantics.dispose();
      });
    }
  });
}
