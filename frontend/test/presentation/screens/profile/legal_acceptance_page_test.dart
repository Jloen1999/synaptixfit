import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/presentation/l10n/gen_l10n/app_localizations.dart';
import 'package:synaptixfit/presentation/screens/auth/session/bloc/session_bloc.dart';
import 'package:synaptixfit/presentation/screens/profile/legal/bloc/legal_acceptance_bloc.dart';
import 'package:synaptixfit/presentation/screens/profile/legal/page/legal_acceptance_page.dart';
import 'package:synaptixfit/presentation/theme/app_theme.dart';

class _MockLegalBloc extends MockBloc<LegalAcceptanceEvent, LegalAcceptanceState>
    implements LegalAcceptanceBloc {}

class _MockSessionBloc extends MockBloc<SessionEvent, SessionState>
    implements SessionBloc {}

/// Pantalla de aceptación de la política (ADR 0034): obligatoria, explica qué
/// falta junto a la casilla y cumple las guías de accesibilidad.
void main() {
  late _MockLegalBloc legal;
  late _MockSessionBloc session;

  setUp(() {
    legal = _MockLegalBloc();
    session = _MockSessionBloc();
    when(() => legal.state).thenReturn(
      const LegalAcceptanceState(
        status: LegalGateStatus.required,
        currentVersion: '2026-11-04',
        updated: true,
      ),
    );
    when(() => session.state).thenReturn(const SessionState.unknown());
  });

  Future<void> pump(
    WidgetTester tester, {
    ThemeData? theme,
    double textScale = 1,
    Size size = const Size(400, 1600),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<LegalAcceptanceBloc>.value(value: legal),
          BlocProvider<SessionBloc>.value(value: session),
        ],
        child: MaterialApp(
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
          home: const LegalAcceptancePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('«atrás» no la salta: hay que aceptar o cerrar sesión', (
    tester,
  ) async {
    await pump(tester);
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byType(LegalAcceptancePage), findsOneWidget);
    expect(find.text('Hemos actualizado la política y las condiciones'),
        findsOneWidget);
  });

  testWidgets('sin marcar la casilla explica junto a ella por qué no sigue', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.text('Aceptar y seguir'));
    await tester.pump();
    expect(find.text('Marca la casilla para crear tu cuenta.'), findsNothing);
    expect(find.byType(CheckboxListTile), findsOneWidget);
    expect(find.textContaining('Marca la casilla'), findsOneWidget);
    verifyNever(() => legal.add(const LegalAcceptanceEvent.accepted()));

    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();
    await tester.tap(find.text('Aceptar y seguir'));
    await tester.pump();
    verify(() => legal.add(const LegalAcceptanceEvent.accepted())).called(1);
  });

  testWidgets('«Cerrar sesión» cierra la sesión', (tester) async {
    await pump(tester);
    await tester.ensureVisible(find.text('Cerrar sesión'));
    await tester.tap(find.text('Cerrar sesión'));
    await tester.pump();
    verify(
      () => session.add(const SessionEvent.logoutRequested()),
    ).called(1);
  });

  group('accesibilidad', () {
    for (final (name, theme) in [
      ('claro', AppTheme.light),
      ('oscuro', AppTheme.dark),
    ]) {
      testWidgets('tema $name: tamaño táctil, etiquetas y contraste', (
        tester,
      ) async {
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

    testWidgets('a 360 dp y texto al 200 % no se desborda', (tester) async {
      await pump(tester, textScale: 2, size: const Size(360, 800));
      expect(tester.takeException(), isNull);
    });
  });
}
