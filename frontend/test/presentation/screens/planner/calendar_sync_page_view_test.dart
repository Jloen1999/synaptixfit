import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/app/di/app_di.dart';
import 'package:synaptixfit/domain/enums/planner_enums.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/planner/calendar_feed.dart';
import 'package:synaptixfit/domain/models/planner/planner_ai.dart';
import 'package:synaptixfit/presentation/l10n/gen_l10n/app_localizations.dart';
import 'package:synaptixfit/presentation/screens/planner/calendar_sync/bloc/calendar_sync_bloc.dart';
import 'package:synaptixfit/presentation/screens/planner/calendar_sync/page/calendar_sync_page.dart';
import 'package:synaptixfit/presentation/theme/app_theme.dart';

class _MockBloc extends MockBloc<CalendarSyncEvent, CalendarSyncState>
    implements CalendarSyncBloc {}

void main() {
  late _MockBloc bloc;
  final created = DateTime(2026, 10, 30, 10);

  final states = <String, CalendarSyncState>{
    'sin enlace': const CalendarSyncState(status: CalendarSyncStatus.ready),
    'enlace recién creado': CalendarSyncState(
      status: CalendarSyncStatus.ready,
      feed: CalendarFeedStatus(active: true, activeSince: created),
      link: CalendarFeedLink(
        url: 'https://api.example/api/v1/planner/calendar-feed/abc.ics',
        createdAt: created,
      ),
    ),
    'importado': CalendarSyncState(
      status: CalendarSyncStatus.ready,
      feed: CalendarFeedStatus(active: true, activeSince: created),
      importResult: const IcsImportResult(
        match: IcsMatch.full,
        totalEvents: 5,
        matchingEvents: 2,
        classes: 0,
        exams: 1,
        deliveries: 2,
        created: 3,
        updated: 0,
        imported: true,
      ),
    ),
    'error al importar': const CalendarSyncState(
      status: CalendarSyncStatus.ready,
      urlMissing: true,
      importError: AppError.business('PLANNER_ICS_UNAVAILABLE'),
    ),
  };

  setUpAll(() => initializeDateFormatting('es'));

  setUp(() {
    bloc = _MockBloc();
    getIt.registerFactory<CalendarSyncBloc>(() => bloc);
  });

  tearDown(() => getIt.unregister<CalendarSyncBloc>());

  Future<void> pump(
    WidgetTester tester,
    CalendarSyncState state, {
    ThemeData? theme,
    double textScale = 1,
  }) async {
    when(() => bloc.state).thenReturn(state);
    tester.view.physicalSize = Size(360, 2000 * textScale);
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
        home: const CalendarSyncPage(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('el enlace recién creado va con su aviso y sus botones', (
    tester,
  ) async {
    await pump(tester, states['enlace recién creado']!);

    expect(find.textContaining('Funciona como una contraseña'), findsOneWidget);
    expect(find.text('Copiar enlace'), findsOneWidget);
    expect(find.text('Desactivar enlace'), findsOneWidget);
  });

  testWidgets('los errores de la importación salen junto al campo', (
    tester,
  ) async {
    await pump(tester, states['error al importar']!);

    expect(find.text('Pega la dirección del calendario.'), findsOneWidget);
    expect(
      find.text(
        'No hemos podido descargar el calendario. Inténtalo más tarde.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('el resultado lleva a las entregas', (tester) async {
    await pump(tester, states['importado']!);

    expect(find.textContaining('2 se han asignado'), findsOneWidget);
    expect(find.text('Ver entregas y exámenes'), findsOneWidget);
  });

  group('accesibilidad', () {
    for (final entry in states.entries) {
      testWidgets(
        '${entry.key}: tamaño táctil, etiquetas y contraste en claro y oscuro',
        (tester) async {
          final semantics = tester.ensureSemantics();
          for (final theme in [AppTheme.light, AppTheme.dark]) {
            await pump(tester, entry.value, theme: theme);

            await expectLater(
              tester,
              meetsGuideline(androidTapTargetGuideline),
            );
            await expectLater(
              tester,
              meetsGuideline(labeledTapTargetGuideline),
            );
            // Como en la importación de guías: en claro, la guía de contraste
            // mide 3,26 en cualquier AppTextField (la app usa el tema oscuro).
            if (theme == AppTheme.dark) {
              await expectLater(tester, meetsGuideline(textContrastGuideline));
            }
          }
          semantics.dispose();
        },
      );

      testWidgets('${entry.key}: texto al 200 % sin desbordes', (tester) async {
        await pump(tester, entry.value, textScale: 2);

        expect(tester.takeException(), isNull);
      });
    }
  });
}
