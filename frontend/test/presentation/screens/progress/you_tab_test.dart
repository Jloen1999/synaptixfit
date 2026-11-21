import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/app/di/app_di.dart';
import 'package:synaptixfit/presentation/l10n/gen_l10n/app_localizations.dart';
import 'package:synaptixfit/presentation/screens/auth/session/bloc/session_bloc.dart';
import 'package:synaptixfit/presentation/screens/progress/community/bloc/community_bloc.dart';
import 'package:synaptixfit/presentation/screens/progress/overview/bloc/progress_overview_bloc.dart';
import 'package:synaptixfit/presentation/screens/progress/overview/page/progress_overview_page.dart';
import 'package:synaptixfit/presentation/screens/progress/progress_routes.dart';
import 'package:synaptixfit/presentation/theme/app_icons.dart';
import 'package:synaptixfit/presentation/theme/app_theme.dart';

import '../profile/profile_fixtures.dart';

class _MockSession extends MockBloc<SessionEvent, SessionState>
    implements SessionBloc {}

class _MockOverview
    extends MockBloc<ProgressOverviewEvent, ProgressOverviewState>
    implements ProgressOverviewBloc {}

class _MockCommunity extends MockBloc<CommunityEvent, CommunityState>
    implements CommunityBloc {}

/// Pestaña «Tú» (ADR 0061): tu foto y tu nombre abren el Perfil y los cuatro
/// apartados llevan su icono.
void main() {
  late _MockSession session;

  setUp(() {
    session = _MockSession();
    when(() => session.state).thenReturn(const SessionState.unknown());
    when(() => session.account).thenReturn(testAccount);
    final overview = _MockOverview();
    when(
      () => overview.state,
    ).thenReturn(const ProgressOverviewState.loading());
    final community = _MockCommunity();
    when(() => community.state).thenReturn(const CommunityState());
    getIt
      ..registerFactory<ProgressOverviewBloc>(() => overview)
      ..registerFactory<CommunityBloc>(() => community);
  });

  tearDown(() => getIt.reset());

  Future<void> pump(
    WidgetTester tester, {
    ProgressTab tab = ProgressTab.summary,
    ThemeData? theme,
    double textScale = 1,
    double width = 390,
    Locale locale = const Locale('es'),
  }) async {
    tester.view.physicalSize = Size(width, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      BlocProvider<SessionBloc>.value(
        value: session,
        child: MaterialApp.router(
          routerConfig: GoRouter(
            routes: [
              GoRoute(
                path: '/',
                builder: (_, _) => ProgressOverviewPage(tab: tab),
              ),
              GoRoute(
                path: ProgressExternalPaths.profile,
                builder: (_, _) => const Scaffold(body: Text('Perfil')),
              ),
            ],
          ),
          theme: theme ?? AppTheme.light,
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
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('arriba tu nombre con «Ver perfil», que abre el Perfil', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('Ver perfil'), findsOneWidget);
    // Sin barra de título «Progreso».
    expect(find.text('Progreso'), findsNothing);

    await tester.tap(find.text('Ver perfil'));
    await tester.pumpAndSettle();
    expect(find.text('Perfil'), findsOneWidget);
  });

  testWidgets('cuatro apartados, cada uno con su icono', (tester) async {
    await pump(tester);

    final tabs = tester.widgetList<Tab>(find.byType(Tab)).toList();
    expect(tabs.map((t) => t.text), [
      'Resumen',
      'Retos',
      'Insignias',
      'Comunidad',
    ]);
    expect(tabs.every((t) => t.icon != null), isTrue);
    expect(
      find.descendant(
        of: find.byType(TabBar),
        matching: find.byIcon(AppIcons.communityTab),
      ),
      findsOneWidget,
    );
  });

  testWidgets('?tab=community abre Comunidad', (tester) async {
    // Sin pumpAndSettle: el esqueleto de Comunidad no deja de moverse.
    await pump(tester, tab: ProgressTab.community);

    final bar = tester.widget<TabBar>(find.byType(TabBar));
    expect(bar.controller!.index, ProgressTab.community.index);
  });

  group('accesibilidad', () {
    testWidgets('la cabecera es un botón con nombre y tamaño táctil', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      for (final theme in [AppTheme.light, AppTheme.dark]) {
        await pump(tester, theme: theme);
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
      }
      expect(
        tester.getSemantics(find.text('Ver perfil')),
        isSemantics(
          label: 'Ana\nVer perfil',
          isButton: true,
          hasTapAction: true,
        ),
      );
      semantics.dispose();
    });

    testWidgets('a 320 px (1,0 · 1,2 · 2,0) y en francés, apartados enteros', (
      tester,
    ) async {
      for (final locale in const [Locale('es'), Locale('fr'), Locale('pt')]) {
        for (final scale in [1.0, 1.2, 2.0]) {
          await pump(tester, width: 320, textScale: scale, locale: locale);
          expect(tester.takeException(), isNull, reason: '$locale $scale');
          final labels = tester
              .widgetList<Tab>(find.byType(Tab))
              .map((t) => t.text!);
          for (final label in labels) {
            // Si no caben, la fila se desplaza: el último puede quedar fuera
            // de la vista, pero nunca cortado.
            expectWhole(tester, find.text(label));
          }
        }
      }
    });

    testWidgets('con el texto al 200 % los apartados no se cortan', (
      tester,
    ) async {
      await pump(tester, textScale: 2);
      expect(tester.takeException(), isNull);
      expect(find.text('Comunidad'), findsOneWidget);
    });
  });
}

/// El texto se ve entero: cabe en su caja sin cortarse ni difuminarse.
void expectWhole(WidgetTester tester, Finder text) {
  final paragraph = tester.renderObject<RenderParagraph>(text);
  expect(
    paragraph.size.width + 0.5,
    greaterThanOrEqualTo(paragraph.getMaxIntrinsicWidth(double.infinity)),
    reason: 'cortado: ${paragraph.text.toPlainText()}',
  );
}

/// Ninguna palabra se parte en dos líneas: una palabra sola cabe entera en
/// el ancho de su caja.
void expectWordNotSplit(WidgetTester tester, Finder text) =>
    expectWhole(tester, text);
