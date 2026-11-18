import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/domain/enums/training_enums.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/models/training/exercise.dart';
import 'package:synaptixfit/domain/models/training/media_credit.dart';
import 'package:synaptixfit/domain/use_cases/training/get_exercise_media_credits_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/get_exercise_use_case.dart';
import 'package:synaptixfit/presentation/l10n/gen_l10n/app_localizations.dart';
import 'package:synaptixfit/presentation/screens/training/exercise_detail/bloc/exercise_detail_bloc.dart';
import 'package:synaptixfit/presentation/screens/training/widgets/exercise_media_credits.dart';
import 'package:synaptixfit/presentation/theme/app_theme.dart';

class _MockGetExercise extends Mock implements GetExerciseUseCaseContract {}

class _MockGetCredits extends Mock
    implements GetExerciseMediaCreditsUseCaseContract {}

/// Crédito de la foto y el vídeo de un ejercicio (ADR 0056).
void main() {
  const exercise = Exercise(
    id: 'e1',
    name: 'Curl de bíceps con barra',
    difficulty: ExerciseDifficulty.beginner,
    modality: Modality.strength,
    met: 3.5,
  );
  const photo = MediaCredit(
    kind: MediaCreditKind.photo,
    source: 'wger',
    license: 'CC BY-SA 3.0',
    licenseUrl: 'https://creativecommons.org/licenses/by-sa/3.0/',
    author: 'Everkinetic',
  );
  const video = MediaCredit(
    kind: MediaCreditKind.video,
    source: 'wger',
    license: 'CC BY-SA 4.0',
    licenseUrl: 'https://creativecommons.org/licenses/by-sa/4.0/',
  );

  late _MockGetExercise getExercise;
  late _MockGetCredits getCredits;

  setUp(() {
    getExercise = _MockGetExercise();
    getCredits = _MockGetCredits();
    when(
      () => getExercise('e1'),
    ).thenAnswer((_) async => const Success(exercise));
  });

  group('ficha del ejercicio', () {
    blocTest<ExerciseDetailBloc, ExerciseDetailState>(
      'trae el ejercicio con el crédito de su foto y su vídeo',
      setUp: () => when(
        () => getCredits('e1'),
      ).thenAnswer((_) async => const Success([photo, video])),
      build: () =>
          ExerciseDetailBloc(getExercise: getExercise, getCredits: getCredits),
      act: (bloc) => bloc.add(const ExerciseDetailEvent.started('e1')),
      expect: () => const [
        ExerciseDetailState.loading(),
        ExerciseDetailState.loaded(exercise, credits: [photo, video]),
      ],
    );

    blocTest<ExerciseDetailBloc, ExerciseDetailState>(
      'si el crédito no llega, la ficha sale igual, sin él',
      setUp: () => when(
        () => getCredits('e1'),
      ).thenAnswer((_) async => const Failure(AppError.network())),
      build: () =>
          ExerciseDetailBloc(getExercise: getExercise, getCredits: getCredits),
      act: (bloc) => bloc.add(const ExerciseDetailEvent.started('e1')),
      expect: () => const [
        ExerciseDetailState.loading(),
        ExerciseDetailState.loaded(exercise),
      ],
    );
  });

  group('créditos en pantalla', () {
    Future<void> pump(
      WidgetTester tester, {
      ThemeData? theme,
      List<MediaCredit> credits = const [photo, video],
      double textScale = 1,
    }) async {
      tester.view.physicalSize = const Size(320, 900);
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
          home: Scaffold(body: ExerciseMediaCredits(credits: credits)),
        ),
      );
    }

    testWidgets('una sola línea, sin jerga, que se lee como créditos', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pump(tester);
      expect(
        find.text('Foto: Everkinetic (wger) · Vídeo: wger'),
        findsOneWidget,
      );
      expect(find.textContaining('CC BY'), findsNothing);
      expect(
        tester.getSemantics(
          find.bySemanticsLabel(
            'Créditos: Foto: Everkinetic (wger) · Vídeo: wger',
          ),
        ),
        isSemantics(
          isButton: true,
          hasTapAction: true,
          onTapHint: 'Ver de dónde salen',
        ),
      );
      semantics.dispose();
    });

    testWidgets('la hoja explica cada licencia y enlaza fuera de la app', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pump(tester);
      await tester.tap(find.text('Foto: Everkinetic (wger) · Vídeo: wger'));
      await tester.pumpAndSettle();
      expect(find.text('Créditos'), findsOneWidget);
      expect(find.text('Licencia libre: CC BY-SA 3.0'), findsOneWidget);
      expect(find.text('Ver licencia'), findsNWidgets(2));
      expect(
        tester.getSemantics(find.text('Ver licencia').first),
        isSemantics(isLink: true, hint: 'Se abre en el navegador'),
      );
      semantics.dispose();
    });

    testWidgets('si el enlace no se puede abrir, lo avisa', (tester) async {
      await pump(
        tester,
        credits: const [
          MediaCredit(
            kind: MediaCreditKind.photo,
            source: 'wger',
            license: 'CC0 1.0',
            licenseUrl: 'http://example.org/no-seguro',
          ),
        ],
      );
      await tester.tap(find.text('Foto: wger'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ver licencia'));
      await tester.pump();
      expect(find.text('No se ha podido abrir el enlace.'), findsOneWidget);
    });

    testWidgets('sin créditos no ocupa sitio', (tester) async {
      await pump(tester, credits: const []);
      expect(find.byType(InkWell), findsNothing);
    });

    testWidgets('táctil, etiquetas, contraste y texto al 200 %', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      for (final theme in [AppTheme.light, AppTheme.dark]) {
        await pump(tester, theme: theme);
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
      }
      await pump(tester, textScale: 2);
      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });
  });
}
