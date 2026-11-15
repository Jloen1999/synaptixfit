import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synaptixfit/app/di/app_di.dart';
import 'package:synaptixfit/domain/enums/training_enums.dart';
import 'package:synaptixfit/domain/models/result/app_result.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/models/training/routine.dart';
import 'package:synaptixfit/domain/models/training/routine_template.dart';
import 'package:synaptixfit/domain/use_cases/training/list_routine_templates_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/use_routine_template_use_case.dart';
import 'package:synaptixfit/presentation/l10n/gen_l10n/app_localizations.dart';
import 'package:synaptixfit/presentation/screens/training/routine_templates/bloc/routine_templates_bloc.dart';
import 'package:synaptixfit/presentation/screens/training/routine_templates/page/routine_templates_page.dart';
import 'package:synaptixfit/presentation/theme/app_theme.dart';

/// Plantillas de rutina (ADR 0043, cierre del plan premium): la lista se ve al
/// entrar y los filtros van en una hoja que dice cuántas quedan.

const _home = RoutineTemplate(
  id: 't1',
  code: 'casa_2',
  name: 'En casa · 2 días',
  place: TemplatePlace.home,
  minutes: 35,
  weeks: 4,
  daysPerWeek: 2,
);
const _gym = RoutineTemplate(
  id: 't2',
  code: 'cuerpo_completo_3',
  name: 'Cuerpo completo · 3 días',
  minutes: 50,
  weeks: 4,
  daysPerWeek: 3,
);

class _List implements ListRoutineTemplatesUseCaseContract {
  @override
  Future<AppResult<List<RoutineTemplate>>> call() async =>
      const Success([_home, _gym]);
}

class _Use implements UseRoutineTemplateUseCaseContract {
  @override
  Future<AppResult<Routine>> call(String templateId) =>
      throw UnimplementedError();
}

void main() {
  setUp(() {
    getIt.registerFactory<RoutineTemplatesBloc>(
      () => RoutineTemplatesBloc(list: _List(), use: _Use()),
    );
  });

  tearDown(() => getIt.unregister<RoutineTemplatesBloc>());

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 1600);
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
        home: const RoutineTemplatesPage(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('la lista se ve al entrar y los filtros van en una hoja', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('En casa · 2 días'), findsOneWidget);
    expect(find.text('Dónde'), findsNothing);

    await tester.tap(find.text('Filtrar'));
    await tester.pumpAndSettle();
    expect(find.text('Dónde'), findsOneWidget);
    expect(find.text('Ver 2 plantillas'), findsOneWidget);

    await tester.tap(find.text('En casa'));
    await tester.pumpAndSettle();
    expect(find.text('Ver 1 plantilla'), findsOneWidget);

    await tester.tap(find.text('Ver 1 plantilla'));
    await tester.pumpAndSettle();
    expect(find.text('Filtrar (1)'), findsOneWidget);
    expect(find.text('Quitar filtros'), findsOneWidget);
    expect(find.text('Cuerpo completo · 3 días'), findsNothing);
  });
}
