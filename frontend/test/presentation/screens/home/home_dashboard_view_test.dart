import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/presentation/l10n/gen_l10n/app_localizations.dart';
import 'package:synaptixfit/presentation/screens/auth/session/bloc/session_bloc.dart';
import 'package:synaptixfit/presentation/screens/home/dashboard/bloc/home_dashboard_bloc.dart';
import 'package:synaptixfit/presentation/screens/home/dashboard/page/home_dashboard_page.dart';
import 'package:synaptixfit/presentation/theme/app_theme.dart';

import 'home_fixtures.dart';

class _MockHomeBloc extends MockBloc<HomeDashboardEvent, HomeDashboardState>
    implements HomeDashboardBloc {}

class _MockSessionBloc extends MockBloc<SessionEvent, SessionState>
    implements SessionBloc {}

void main() {
  late _MockHomeBloc home;
  late _MockSessionBloc session;

  setUpAll(() => initializeDateFormatting('es'));

  setUp(() {
    home = _MockHomeBloc();
    session = _MockSessionBloc();
    when(() => session.state).thenReturn(const SessionState.unknown());
    when(() => session.account).thenReturn(null);
  });

  Future<void> pump(
    WidgetTester tester, {
    ThemeData? theme,
    double textScale = 1,
  }) async {
    tester.view.physicalSize = Size(390, 2400 * textScale);
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
        home: MultiBlocProvider(
          providers: [
            BlocProvider<SessionBloc>.value(value: session),
            BlocProvider<HomeDashboardBloc>.value(value: home),
          ],
          child: const HomeDashboardView(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
  }

  testWidgets('pinta todas las secciones del inicio', (tester) async {
    when(() => home.state).thenReturn(
      HomeDashboardState(
        status: HomeDashboardStatus.loaded,
        dashboard: homeDashboardFixture,
        dueReviews: homeReviewsFixture,
        unreadNotifications: 3,
      ),
    );

    await pump(tester);

    expect(find.textContaining('Ana'), findsWidgets);
    expect(find.text('Tienes 2 entregas próximas'), findsOneWidget);
    expect(find.text('Ver entregas'), findsOneWidget);
    expect(find.text('Carga cognitiva'), findsOneWidget);
    expect(find.text('Cálculo'), findsOneWidget);
    expect(find.text('Tema 3: Límites'), findsOneWidget);
    expect(find.text('Fuerza base'), findsOneWidget);
    expect(find.text('Hacer check-in'), findsOneWidget);
    expect(find.text('Estudiar 10 horas'), findsOneWidget);
    // La recomendación termina en una acción: empezar a estudiar.
    expect(find.text('Concentrarme'), findsOneWidget);
    // La regulación cruzada termina en una recomendación de una línea.
    expect(find.textContaining('bloques de 52 min'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('se ve sin errores en tema oscuro', (tester) async {
    when(() => home.state).thenReturn(
      HomeDashboardState(
        status: HomeDashboardStatus.loaded,
        dashboard: homeDashboardFixture,
      ),
    );

    await pump(tester, theme: AppTheme.dark);

    expect(find.text('Tu equilibrio'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('muestra el error con reintento', (tester) async {
    when(() => home.state).thenReturn(
      const HomeDashboardState(
        status: HomeDashboardStatus.failure,
        error: AppError.network(),
      ),
    );

    await pump(tester);
    await tester.tap(find.text('Reintentar'));

    verify(() => home.add(const HomeDashboardEvent.refreshed())).called(1);
  });

  group('accesibilidad', () {
    setUp(
      () => when(() => home.state).thenReturn(
        HomeDashboardState(
          status: HomeDashboardStatus.loaded,
          dashboard: homeDashboardFixture,
          dueReviews: homeReviewsFixture,
        ),
      ),
    );

    testWidgets('cumple las guías de tamaño táctil, etiquetas y contraste', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pump(tester);

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      semantics.dispose();
    });

    testWidgets('con el texto al 200 % no se corta ni se solapa', (
      tester,
    ) async {
      await pump(tester, textScale: 2);

      expect(find.text('Tu equilibrio'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
