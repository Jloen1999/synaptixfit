import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/app/di/app_di.dart';
import 'package:synaptixfit/domain/models/training/sport_activity.dart';
import 'package:synaptixfit/presentation/l10n/gen_l10n/app_localizations.dart';
import 'package:synaptixfit/presentation/screens/training/past_activity/bloc/past_activity_bloc.dart';
import 'package:synaptixfit/presentation/screens/training/past_activity/page/past_activity_page.dart';
import 'package:synaptixfit/presentation/screens/training/sports/page/other_sport_page.dart';
import 'package:synaptixfit/presentation/screens/training/sports/page/sport_run_page.dart';
import 'package:synaptixfit/presentation/screens/training/widgets/training_section_bar.dart';
import 'package:synaptixfit/presentation/theme/app_theme.dart';
import 'package:synaptixfit/presentation/widgets/widgets.dart';

class _MockBloc extends MockBloc<PastActivityEvent, PastActivityState>
    implements PastActivityBloc {}

/// Formulario de apuntar por deporte y las pantallas «Correr, andar o bici» y
/// «Otro deporte» (ADR 0068).
void main() {
  late _MockBloc bloc;

  setUpAll(() {
    registerFallbackValue(const PastActivityEvent.routineRequested());
    return initializeDateFormatting('es');
  });

  setUp(() {
    bloc = _MockBloc();
    when(() => bloc.state).thenReturn(const PastActivityState());
    getIt.registerFactory<PastActivityBloc>(() => bloc);
  });

  tearDown(() => getIt.unregister<PastActivityBloc>());

  Future<void> pump(
    WidgetTester tester,
    Widget page, {
    double width = 360,
    double scale = 1,
  }) async {
    tester.view.physicalSize = Size(width, 2400 * scale);
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
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: page,
      ),
    );
    await tester.pumpAndSettle();
  }

  const padel = PastActivityPage(from: TrainingSection.run, sport: Sport.padel);

  testWidgets('un deporte de partido pide partido o entreno y el resultado, '
      'con «Guardar partido» a la vista', (tester) async {
    await pump(tester, padel);
    expect(find.text('Pádel'), findsOneWidget);
    // Sin elegir tipo ni «día de mi rutina»: el deporte ya está elegido.
    expect(find.text('Tipo'), findsNothing);
    expect(find.text('Día de mi rutina'), findsNothing);
    expect(find.text('Partido'), findsOneWidget);
    expect(find.text('Entreno o clase'), findsOneWidget);
    for (final text in ['Ganado', 'Empate', 'Perdido', 'Marcador (opcional)']) {
      expect(find.text(text), findsOneWidget, reason: text);
    }
    // Una sola acción principal, abajo fija.
    expect(find.widgetWithText(AppPrimaryButton, 'Guardar partido'), findsOne);
    expect(find.byType(AppPrimaryButton), findsOneWidget);
  });

  testWidgets('un entreno no pide resultado y el botón lo dice', (
    tester,
  ) async {
    await pump(tester, padel);
    await tester.tap(find.text('Entreno o clase'));
    await tester.pumpAndSettle();
    expect(find.text('Ganado'), findsNothing);
    expect(find.text('Marcador (opcional)'), findsNothing);
    expect(find.widgetWithText(AppPrimaryButton, 'Guardar entreno'), findsOne);
  });

  testWidgets('natación pide metros y «otro deporte», su nombre', (
    tester,
  ) async {
    await pump(
      tester,
      const PastActivityPage(from: TrainingSection.run, sport: Sport.swim),
    );
    expect(find.text('Distancia en metros (opcional)'), findsOneWidget);
    expect(find.text('Partido'), findsNothing);

    await pump(
      tester,
      const PastActivityPage(
        key: ValueKey('other'),
        from: TrainingSection.run,
        sport: Sport.other,
        sportName: 'Escalada',
      ),
    );
    expect(find.text('Escalada'), findsOneWidget);
    expect(find.text('¿Qué deporte fue?'), findsOneWidget);
    expect(find.text('Distancia en metros (opcional)'), findsNothing);
  });

  testWidgets('«otro deporte» sin nombre no se guarda y dice por qué', (
    tester,
  ) async {
    await pump(
      tester,
      const PastActivityPage(from: TrainingSection.run, sport: Sport.other),
    );
    await tester.tap(find.byType(AppPrimaryButton));
    await tester.pumpAndSettle();
    expect(find.text('Escribe qué deporte fue.'), findsOneWidget);
    verifyNever(() => bloc.add(any()));
  });

  testWidgets('sin deporte sigue el formulario general de siempre', (
    tester,
  ) async {
    await pump(tester, const PastActivityPage());
    expect(find.text('Apuntar actividad'), findsOneWidget);
    expect(find.text('Tipo'), findsOneWidget);
    expect(find.text('Día de mi rutina'), findsOneWidget);
  });

  for (final (name, page) in <(String, Widget)>[
    ('partido', padel),
    ('correr, andar o bici', const SportRunPage()),
    ('correr, andar o bici sin GPS', const SportRunPage(gps: false)),
    ('otro deporte', const OtherSportPage()),
  ]) {
    testWidgets('$name: a 320 px y con el texto al 200 % no se desborda', (
      tester,
    ) async {
      await pump(tester, page, width: 320, scale: 2);
      expect(tester.takeException(), isNull);
    });

    testWidgets('$name: cumple las guías de accesibilidad', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, page);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });
  }

  testWidgets('«Correr, andar o bici»: empezar es la acción principal y '
      'sin GPS se apunta a mano', (tester) async {
    await pump(tester, const SportRunPage());
    for (final text in ['Correr', 'Andar', 'Bici']) {
      expect(find.text(text), findsOneWidget, reason: text);
    }
    expect(find.widgetWithText(AppPrimaryButton, 'Empezar'), findsOneWidget);
    expect(find.text('Apuntar una ya hecha'), findsOneWidget);
    expect(find.text('Crear entreno guiado'), findsOneWidget);
    expect(
      find.text('Series que la app te va diciendo mientras corres'),
      findsOneWidget,
    );

    await pump(tester, const SportRunPage(key: ValueKey('web'), gps: false));
    expect(find.text('Empezar'), findsNothing);
    expect(
      find.widgetWithText(AppPrimaryButton, 'Apuntar una ya hecha'),
      findsOneWidget,
    );
  });

  testWidgets('«Otro deporte»: el buscador filtra y ofrece añadir lo escrito', (
    tester,
  ) async {
    await pump(tester, const OtherSportPage());
    expect(find.text('Vóley'), findsOneWidget);
    expect(find.text('Yoga'), findsOneWidget);
    expect(find.byKey(const ValueKey('sport-add-typed')), findsNothing);

    await tester.enterText(find.byType(TextField), 'esgrima');
    await tester.pumpAndSettle();
    expect(find.text('Añadir «esgrima»'), findsOneWidget);
    expect(find.text('Yoga'), findsNothing);

    // Lo que ya está en la lista no se «añade»: se elige.
    await tester.enterText(find.byType(TextField), 'yoga');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('sport-add-typed')), findsNothing);
  });
}
