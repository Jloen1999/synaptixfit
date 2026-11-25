import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/domain/enums/pass_outlook.dart';
import 'package:synaptixfit/domain/enums/syllabus_topic_kind.dart';
import 'package:synaptixfit/domain/models/academic/teaching_guide.dart';
import 'package:synaptixfit/presentation/l10n/gen_l10n/app_localizations.dart';
import 'package:synaptixfit/presentation/screens/academic/subject_detail/bloc/subject_detail_bloc.dart';
import 'package:synaptixfit/presentation/screens/academic/subject_detail/bloc/subject_progress_bloc.dart';
import 'package:synaptixfit/presentation/screens/academic/subject_detail/page/evaluation_tab.dart';
import 'package:synaptixfit/presentation/screens/academic/subject_detail/page/guide_tab.dart';
import 'package:synaptixfit/presentation/screens/academic/subject_detail/page/subject_detail_page.dart';
import 'package:synaptixfit/presentation/screens/academic/subject_detail/page/summary_tab.dart';
import 'package:synaptixfit/presentation/screens/academic/subject_detail/page/topics_tab.dart';
import 'package:synaptixfit/presentation/theme/app_theme.dart';

import 'academic_fixtures.dart';

class _Progress extends MockBloc<SubjectProgressEvent, SubjectProgressState>
    implements SubjectProgressBloc {}

class _Detail extends MockBloc<SubjectDetailEvent, SubjectDetailState>
    implements SubjectDetailBloc {}

/// Pestañas de la asignatura (ADR 0057): sus vacíos sin guía docente, «Tu
/// nota» con cada frase y el profesorado con y sin correo.
void main() {
  setUpAll(() => initializeDateFormatting('es'));

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    SubjectProgressState? progress,
    double scale = 1,
  }) async {
    final progressBloc = _Progress();
    final detailBloc = _Detail();
    when(() => progressBloc.state).thenReturn(
      progress ?? const SubjectProgressState(subjectId: 's1', loading: false),
    );
    when(
      () => detailBloc.state,
    ).thenReturn(const SubjectDetailState(subjectId: 's1', loading: false));
    tester.view.physicalSize = Size(360, 1800 * scale);
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
        builder: (context, app) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: app!,
        ),
        home: MultiBlocProvider(
          providers: [
            BlocProvider<SubjectProgressBloc>.value(value: progressBloc),
            BlocProvider<SubjectDetailBloc>.value(value: detailBloc),
          ],
          child: Scaffold(body: child),
        ),
      ),
    );
    await tester.pump();
  }

  group('pestañas por enlace', () {
    test('?tab= abre la suya; uno desconocido, el Resumen; Apuntes va antes '
        'que Evaluación (ADR 0064)', () {
      expect(SubjectDetailTab.fromQuery('notes'), SubjectDetailTab.notes);
      expect(SubjectDetailTab.fromQuery('guide'), SubjectDetailTab.guide);
      expect(SubjectDetailTab.fromQuery('progress'), SubjectDetailTab.summary);
      expect(SubjectDetailTab.fromQuery(null), SubjectDetailTab.summary);
      expect(SubjectDetailTab.values.map((t) => t.name), [
        'summary',
        'topics',
        'notes',
        'evaluation',
        'guide',
      ]);
    });
  });

  group('sin guía docente, cada pestaña invita a importarla', () {
    for (final (name, tab, title) in [
      ('Temario', const TopicsTab(), 'Aún no hay temario'),
      ('Evaluación', const EvaluationTab(), 'Aún no sabes cómo te evalúan'),
      ('Guía', const GuideTab(), 'Aún no has importado la guía'),
    ]) {
      testWidgets(name, (tester) async {
        await pump(tester, tab);
        expect(tester.takeException(), isNull);
        expect(find.text(title), findsOneWidget);
        expect(find.text('Importar guía docente'), findsOneWidget);
      });
    }

    testWidgets('Resumen: invita a importarla en vez de «De un vistazo»', (
      tester,
    ) async {
      await pump(tester, const SummaryTab());
      expect(tester.takeException(), isNull);
      expect(find.text('Importar guía docente'), findsOneWidget);
      expect(find.text('Temas hechos'), findsNothing);
      expect(find.text('Nada que repasar hoy'), findsOneWidget);
      expect(find.text('Crear preguntas'), findsOneWidget);
      expect(find.text('Simulacro'), findsOneWidget);
    });
  });

  testWidgets('Resumen con guía: repasos de hoy y de un vistazo (200 %)', (
    tester,
  ) async {
    await pump(
      tester,
      const SummaryTab(),
      scale: 2,
      progress: SubjectProgressState(
        subjectId: 's1',
        loading: false,
        retention: retention,
        due: const [material],
        guide: guide.copyWith(
          estimate: const GradeEstimate(
            estimatedGrade: 6.9,
            coveredPercentage: 45,
            earnedPoints: 3.1,
            possiblePoints: 4.5,
            requiredGradeToPass: 3.5,
            outlook: PassOutlook.needsAverage,
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('1 repaso para hoy'), findsOneWidget);
    expect(find.text('Repasar'), findsOneWidget);
    expect(find.text('50 %'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Temas hechos'), 200);
    expect(find.text('0 de 1'), findsOneWidget);
    expect(find.text('3,1 de 4,5 puntos'), findsOneWidget);
  });

  testWidgets('Temario: cuenta los hechos y marca con la casilla', (
    tester,
  ) async {
    await pump(
      tester,
      const TopicsTab(),
      progress: SubjectProgressState(
        subjectId: 's1',
        loading: false,
        guide: guide.copyWith(
          topics: const [
            SyllabusTopic(
              index: 0,
              title: 'Tema 1',
              kind: SyllabusTopicKind.theory,
              completed: true,
            ),
            SyllabusTopic(
              index: 1,
              title: 'Práctica 1',
              kind: SyllabusTopicKind.practice,
              completed: false,
            ),
          ],
        ),
      ),
    );
    expect(find.text('1 de 2 temas hechos'), findsOneWidget);
    expect(find.text('50 %'), findsOneWidget);
    expect(find.byType(CheckboxListTile), findsNWidgets(2));
  });

  group('Tu nota', () {
    Future<void> pumpGrade(WidgetTester tester, GradeEstimate? e) =>
        pump(tester, SingleChildScrollView(child: YourGradeCard(estimate: e)));

    testWidgets('sin notas: invita a ponerlas, sin cifras', (tester) async {
      await pumpGrade(
        tester,
        const GradeEstimate(estimatedGrade: 0, coveredPercentage: 0),
      );
      expect(
        find.text(
          'Pon tus notas cuando las sepas y verás cuánto te falta para aprobar.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('puntos'), findsNothing);
    });

    testWidgets('con notas: puntos y la media que basta en lo que queda', (
      tester,
    ) async {
      await pumpGrade(
        tester,
        const GradeEstimate(
          estimatedGrade: 6.9,
          coveredPercentage: 45,
          requiredGradeToPass: 3.5,
          earnedPoints: 3.1,
          possiblePoints: 4.5,
          outlook: PassOutlook.needsAverage,
        ),
      );
      expect(find.text('3,1 de 4,5 puntos'), findsOneWidget);
      expect(
        find.text('Lo que llevas de lo ya evaluado (45 % de la nota).'),
        findsOneWidget,
      );
      expect(
        find.text('Para aprobar te basta un 3,5 de media en lo que queda.'),
        findsOneWidget,
      );
    });

    testWidgets('ya aprobado', (tester) async {
      await pumpGrade(
        tester,
        const GradeEstimate(
          estimatedGrade: 8.5,
          coveredPercentage: 60,
          earnedPoints: 5.1,
          possiblePoints: 6,
          outlook: PassOutlook.alreadyPassed,
        ),
      );
      expect(find.text('Ya tienes el aprobado asegurado.'), findsOneWidget);
    });

    testWidgets('ya no se llega', (tester) async {
      await pumpGrade(
        tester,
        const GradeEstimate(
          estimatedGrade: 0.5,
          coveredPercentage: 60,
          requiredGradeToPass: 10,
          earnedPoints: 0.3,
          possiblePoints: 6,
          outlook: PassOutlook.outOfReach,
        ),
      );
      expect(find.text('Con estas notas ya no llegas al 5.'), findsOneWidget);
      expect(find.textContaining('te basta'), findsNothing);
    });
  });

  group('Profesorado', () {
    testWidgets('con correo: papel, tutorías y «Escribir»', (tester) async {
      final semantics = tester.ensureSemantics();
      await pump(
        tester,
        const ProfessorCard(
          professor: Professor(
            name: 'Ana Ruiz',
            email: 'ana@uni.es',
            office: '2.15 (edificio B)',
            role: 'Coordinadora · Teoría',
            officeHours: 'Lun 10:00–12:00',
          ),
        ),
      );
      expect(find.text('Coordinadora · Teoría'), findsOneWidget);
      expect(find.textContaining('2.15 (edificio B)'), findsOneWidget);
      expect(find.textContaining('Lun 10:00–12:00'), findsOneWidget);
      expect(find.text('Escribir'), findsOneWidget);
      // El lector oye a quién se escribe.
      expect(find.bySemanticsLabel('Escribir a Ana Ruiz'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('sin correo no hay botón «Escribir»', (tester) async {
      await pump(
        tester,
        const ProfessorCard(
          professor: Professor(name: 'Luis Gómez', office: 'Lab. 1.04'),
        ),
      );
      expect(find.text('Luis Gómez'), findsOneWidget);
      expect(find.text('Escribir'), findsNothing);
    });
  });
}
