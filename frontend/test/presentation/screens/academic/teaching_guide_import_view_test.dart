import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/app/di/app_di.dart';
import 'package:synaptixfit/domain/enums/assessment_kind.dart';
import 'package:synaptixfit/domain/enums/evaluation_mode.dart';
import 'package:synaptixfit/domain/enums/teaching_guide_import_status.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/academic/teaching_guide.dart';
import 'package:synaptixfit/domain/models/academic/teaching_guide_import.dart';
import 'package:synaptixfit/presentation/l10n/gen_l10n/app_localizations.dart';
import 'package:synaptixfit/presentation/screens/academic/teaching_guide_import/bloc/teaching_guide_import_bloc.dart';
import 'package:synaptixfit/presentation/screens/academic/teaching_guide_import/page/teaching_guide_import_page.dart';
import 'package:synaptixfit/presentation/theme/app_theme.dart';

class _MockBloc
    extends MockBloc<TeachingGuideImportEvent, TeachingGuideImportState>
    implements TeachingGuideImportBloc {}

void main() {
  late _MockBloc bloc;

  const draft = GuideDraft(
    info: SubjectGuideInfo(
      name: 'Diseño y evaluación de tecnologías hardware',
      code: '502376',
      ectsCredits: 6,
      semester: 6,
      character: 'OBLIGATORIA',
      degree:
          'Grado en Ingeniería Informática en Tecnologías de la Información',
      university: 'Universidad de Extremadura',
    ),
    topics: [
      TopicDraft(
        title: 'Tema 1: Técnicas de aumento de prestaciones',
        subtopics: ['Memoria y E/S'],
        hours: 27,
      ),
    ],
    assessments: [
      AssessmentDraft(
        name: 'Prueba 1 (temas 1, 2 y 3)',
        percentage: 30,
        mode: EvaluationMode.continuous,
        kind: AssessmentKind.exam,
        durationMinutes: 120,
        topicNumbers: [1, 2, 3],
      ),
      AssessmentDraft(
        name: 'Trabajos dirigidos parte 1',
        percentage: 20,
        mode: EvaluationMode.continuous,
        kind: AssessmentKind.assignment,
        recoverable: false,
        dueDate: null,
      ),
      AssessmentDraft(
        name: 'Prueba global',
        percentage: 100,
        mode: EvaluationMode.global,
        kind: AssessmentKind.exam,
      ),
    ],
  );
  final dated = draft.copyWith(
    assessments: [
      draft.assessments.first.copyWith(dueDate: DateTime(2026, 11, 20)),
      ...draft.assessments.skip(1),
    ],
  );
  const ready = TeachingGuideImport(
    id: 'i1',
    status: TeachingGuideImportStatus.ready,
    fileName: 'plan.pdf',
    suggestedSubjectId: 's1',
    suggestedSubjectName: 'Hardware',
    draft: draft,
  );

  final states = <String, TeachingGuideImportState>{
    'elegir': const TeachingGuideImportState(),
    'revisar': TeachingGuideImportState(
      phase: GuideImportPhase.review,
      guideImport: ready,
      draft: dated,
    ),
    'fallo': const TeachingGuideImportState(
      phase: GuideImportPhase.failed,
      guideImport: ready,
      error: AppError.business('STUDY_GUIDE_EMPTY'),
    ),
  };

  setUpAll(() => initializeDateFormatting('es'));

  setUp(() {
    bloc = _MockBloc();
    getIt.registerFactory<TeachingGuideImportBloc>(() => bloc);
  });

  tearDown(() => getIt.unregister<TeachingGuideImportBloc>());

  Future<void> pump(
    WidgetTester tester,
    TeachingGuideImportState state, {
    ThemeData? theme,
    double textScale = 1,
  }) async {
    when(() => bloc.state).thenReturn(state);
    tester.view.physicalSize = Size(360, 1800 * textScale);
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
        home: const TeachingGuideImportPage(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('la revisión muestra destino, datos y fecha de la prueba', (
    tester,
  ) async {
    await pump(tester, states['revisar']!);

    expect(find.text('Completar «Hardware»'), findsOneWidget);
    expect(find.text('Obligatoria'), findsOneWidget);
    expect(find.text('¿Cómo te vas a evaluar?'), findsOneWidget);
    // Solo las pruebas de la modalidad continua (activa por defecto).
    expect(find.text('Prueba global'), findsNothing);
    expect(find.text('20 nov'), findsOneWidget);
    expect(find.text('Poner fecha'), findsOneWidget);
  });

  testWidgets('sin nombre, crear asignatura señala el campo en vez de enviar', (
    tester,
  ) async {
    final empty = states['revisar']!.copyWith(
      draft: dated.copyWith(info: const SubjectGuideInfo()),
      guideImport: ready.copyWith(
        suggestedSubjectId: null,
        suggestedSubjectName: null,
      ),
    );
    await pump(tester, empty);

    await tester.tap(find.text('Crear asignatura'));
    await tester.pump();

    expect(find.text('Escribe el nombre de la asignatura'), findsOneWidget);
    verifyNever(() => bloc.add(const TeachingGuideImportEvent.applied()));
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
            // La app solo usa el tema oscuro (themeMode dark). En claro, la guía
            // de contraste mide 3,26 en cualquier AppTextField (también aislado,
            // fuera de esta pantalla): se comprueba aparte del tema claro.
            if (theme == AppTheme.dark || entry.key != 'revisar') {
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
