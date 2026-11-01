import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:synaptixfit/domain/enums/subject_priority.dart';
import 'package:synaptixfit/domain/enums/visibility.dart' as domain;
import 'package:synaptixfit/domain/models/academic/note.dart';
import 'package:synaptixfit/domain/models/academic/subject.dart';
import 'package:synaptixfit/presentation/l10n/gen_l10n/app_localizations.dart';
import 'package:synaptixfit/presentation/screens/academic/widgets/shared_note_card.dart';
import 'package:synaptixfit/presentation/screens/academic/widgets/subject_card.dart';
import 'package:synaptixfit/presentation/theme/app_theme.dart';
import 'package:synaptixfit/presentation/theme/tokens.g.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  double width = 360,
  double scale = 2,
  bool dark = true,
}) async {
  tester.view.physicalSize = Size(width, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: dark ? AppTheme.dark : AppTheme.light,
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
      home: Scaffold(
        body: SingleChildScrollView(
          child: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(() => initializeDateFormatting('es'));

  testWidgets('la asignatura destaca su próxima evaluación (200 %, 360 dp)', (
    tester,
  ) async {
    final today = DateTime.now();
    final subject = Subject(
      id: 's1',
      name: 'Ampliación de Matemáticas',
      code: 'AMAT',
      credits: 6,
      perceivedDifficulty: 3,
      priority: SubjectPriority.values.first,
      nextAssessmentAt: DateTime(today.year, today.month, today.day + 1, 9),
      archived: false,
      noteCount: 4,
      fileCount: 2,
    );
    await _pump(
      tester,
      // El mismo alto que le da la rejilla de Académico con el texto al 200 %.
      SizedBox(
        height: TokensSize.subjectCardHeight * 2,
        child: SubjectCard(subject: subject, onTap: () {}),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('AMAT'), findsOneWidget);
    expect(find.text('Evaluación mañana'), findsOneWidget);

    // Rejilla de dos columnas en un móvil (unos 160 dp) a texto normal y en
    // claro: la evaluación se lee entera (dos líneas, sin puntos suspensivos).
    await _pump(
      tester,
      Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 160,
          height: TokensSize.subjectCardHeight,
          child: SubjectCard(
            subject: subject.copyWith(
              nextAssessmentAt: DateTime(
                today.year,
                today.month,
                today.day + 5,
              ),
            ),
            onTap: () {},
          ),
        ),
      ),
      scale: 1,
      dark: false,
    );
    expect(tester.takeException(), isNull);
    final text = tester.widget<Text>(find.text('Evaluación en 5 días'));
    final painter = TextPainter(
      text: TextSpan(text: text.data, style: text.style),
      textDirection: TextDirection.ltr,
      maxLines: text.maxLines,
    )..layout(maxWidth: tester.getSize(find.byWidget(text)).width);
    expect(painter.didExceedMaxLines, isFalse);
  });

  testWidgets('el apunte compartido separa autor y lectura (200 %, 320 dp)', (
    tester,
  ) async {
    var opened = 0;
    await _pump(
      width: 320,
      tester,
      SharedNoteCard(
        note: SharedNoteSummary(
          id: 'n1',
          authorId: 'u1',
          authorName: 'Ana Pérez',
          catalogSubjectName: 'Física',
          title: 'Resumen del tema 3',
          excerpt: 'Leyes de Newton y ejemplos resueltos.',
          visibility: domain.Visibility.values.last,
          updatedAt: DateTime(2026, 10, 3),
        ),
        onOpen: () => opened++,
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Física'), findsOneWidget);
    await tester.tap(find.text('Resumen del tema 3'));
    expect(opened, 1);
  });
}
