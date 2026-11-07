import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/domain/enums/home_event_kind.dart';
import 'package:synaptixfit/domain/enums/home_event_type.dart';
import 'package:synaptixfit/domain/enums/item_time_status.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/home/home_dashboard.dart';
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
    double width = 390,
    String language = 'es',
  }) async {
    tester.view.physicalSize = Size(width, 2400 * textScale);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? AppTheme.light,
        locale: Locale(language),
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
    // En el móvil el aviso entero lleva a la acción: se anuncia como pista.
    expect(
      find.bySemanticsLabel(RegExp('Tienes 2 entregas próximas')),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.chevron_right_rounded), findsWidgets);
    expect(find.text('Carga cognitiva'), findsOneWidget);
    // En la agenda y en «Tu día» (es el bloque que toca a continuación).
    expect(find.text('Cálculo'), findsNWidgets(2));
    expect(find.text('Tu día'), findsOneWidget);
    expect(find.text('Tema 3: Límites'), findsOneWidget);
    expect(find.text('Fuerza base'), findsOneWidget);
    expect(find.text('Contar cómo estoy'), findsOneWidget);
    expect(find.text('Estudiar 10 horas'), findsOneWidget);
    // La recomendación termina en una acción: empezar a estudiar.
    // Solo en «Tu día»: «Tu equilibrio» ya no lo repite.
    expect(find.text('Concentrarme'), findsOneWidget);
    // La regulación cruzada termina en una recomendación de una línea.
    expect(find.textContaining('concentración de 52 min'), findsOneWidget);
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

    testWidgets(
      'un bloque sin hacer a 360 dp y texto al 200 % lleva el aviso bajo el subtítulo',
      (tester) async {
        when(() => home.state).thenReturn(
          HomeDashboardState(
            status: HomeDashboardStatus.loaded,
            dashboard: homeDashboardFixture.copyWith(
              todayEvents: [
                HomeTodayEvent(
                  id: 'e3',
                  kind: HomeEventKind.block,
                  type: HomeEventType.study,
                  title: 'Repaso de integrales por partes y sustitución',
                  start: DateTime(2026, 10, 18, 8),
                  end: DateTime(2026, 10, 18, 9),
                  completed: false,
                  status: ItemTimeStatus.missed,
                ),
              ],
            ),
          ),
        );

        await pump(tester, textScale: 2, width: 360);

        // La pastilla de la agenda (la leyenda de «Tu semana» también dice
        // «Sin hacer»).
        final pill = find
            .descendant(of: find.byType(ListTile), matching: find.text('Sin hacer'))
            .first;
        expect(pill, findsOneWidget);
        // Debajo del título, no a su derecha.
        expect(
          tester.getTopLeft(pill).dy,
          greaterThan(
            tester
                .getBottomLeft(find.textContaining('Repaso de integrales'))
                .dy,
          ),
        );
        expect(tester.takeException(), isNull);
      },
    );

    for (final language in ['en', 'fr', 'pt']) {
      testWidgets('en $language con texto al 200 % no se rompe', (
        tester,
      ) async {
        Intl.defaultLocale = language;
        addTearDown(() => Intl.defaultLocale = 'es');
        await pump(tester, textScale: 2, width: 360, language: language);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('con el texto al 200 % no se corta ni se solapa', (
      tester,
    ) async {
      await pump(tester, textScale: 2);

      expect(find.text('Tu equilibrio'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
