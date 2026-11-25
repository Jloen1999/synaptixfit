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

  testWidgets(
    'la tarjeta enseña ECTS, curso, temas, repasos y lo próximo (200 %, 360 dp)',
    (tester) async {
      final today = DateTime.now();
      final subject = Subject(
        id: 's1',
        name: 'Bases de datos',
        code: 'BD',
        credits: 6,
        perceivedDifficulty: 3,
        priority: SubjectPriority.values.first,
        teacher: 'Ana Ruiz',
        archived: false,
        noteCount: 4,
        fileCount: 2,
        course: 2,
        term: 1,
        topicsDone: 4,
        topicsTotal: 10,
        reviewsDueToday: 3,
        nextUp: SubjectNextUp(
          kind: SubjectNextUpKind.assessment,
          at: DateTime(today.year, today.month, today.day + 1, 9),
          daysLeft: 1,
          urgent: true,
        ),
      );
      var imported = false;
      await _pump(
        tester,
        SubjectCard(
          subject: subject,
          onTap: () {},
          onImportGuide: () => imported = true,
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('6 ECTS · 2.º curso · 1.er cuatri'), findsOneWidget);
      expect(find.text('Temas 4 de 10'), findsOneWidget);
      expect(find.text('3 repasos hoy'), findsOneWidget);
      expect(find.text('Evaluación mañana'), findsOneWidget);
      // Profesor, siglas y apuntes van en el detalle; con temario no se
      // invita a importar la guía.
      expect(find.text('Ana Ruiz'), findsNothing);
      expect(find.text('BD'), findsNothing);
      expect(find.text('Sin temario: importa la guía'), findsNothing);
      expect(imported, isFalse);
    },
  );

  testWidgets(
    'sin guía: omite lo que falta e invita a importarla (sin toques anidados)',
    (tester) async {
      var opened = false;
      var imported = false;
      await _pump(
        tester,
        SubjectCard(
          subject: const Subject(
            id: 's3',
            name: 'Inglés técnico',
            credits: 3,
            perceivedDifficulty: 3,
            priority: SubjectPriority.medium,
            archived: false,
            noteCount: 0,
            fileCount: 0,
            term: 2,
          ),
          onTap: () => opened = true,
          onImportGuide: () => imported = true,
        ),
        scale: 1,
        dark: false,
      );
      expect(tester.takeException(), isNull);
      // Sin curso: «3 ECTS · 2.º cuatri», sin huecos.
      expect(find.text('3 ECTS · 2.º cuatri'), findsOneWidget);
      expect(find.textContaining('repasos hoy'), findsNothing);
      await tester.tap(find.text('Sin temario: importa la guía'));
      expect(imported, isTrue);
      expect(opened, isFalse);
      await tester.tap(find.text('Inglés técnico'));
      expect(opened, isTrue);
    },
  );

  testWidgets(
    'la tarjeta pinta lo próximo que elige el servidor: entrega o clase',
    (tester) async {
      final subject = Subject(
        id: 's2',
        name: 'Física Cuántica',
        code: 'FQ',
        credits: 6,
        perceivedDifficulty: 3,
        priority: SubjectPriority.values.first,
        teacher: 'Marta Ruiz',
        archived: false,
        noteCount: 1,
        fileCount: 0,
        nextClassAt: DateTime(2026, 11, 9, 10),
        nextClassPlace: 'Aula 2.3',
        classDays: const [1, 3],
        nextDeadline: SubjectDeadline(
          title: 'Práctica 2',
          dueAt: DateTime(2026, 11, 10, 23),
          exam: false,
        ),
        nextUp: SubjectNextUp(
          kind: SubjectNextUpKind.delivery,
          at: DateTime(2026, 11, 10, 23),
          daysLeft: 1,
          urgent: true,
        ),
      );
      expect(SubjectNextUpView.of(subject)!.urgent, isTrue);
      await _pump(tester, SubjectCard(subject: subject, onTap: () {}));
      expect(tester.takeException(), isNull);
      expect(find.text('Física Cuántica'), findsOneWidget);
      expect(find.text('Entrega mañana'), findsOneWidget);

      // Sin entrega urgente: la próxima clase con su aula.
      await _pump(
        tester,
        SubjectCard(
          subject: subject.copyWith(
            nextUp: SubjectNextUp(
              kind: SubjectNextUpKind.classSession,
              at: DateTime(2026, 11, 9, 10),
              place: 'Aula 2.3',
              daysLeft: 0,
              urgent: false,
            ),
          ),
          onTap: () {},
        ),
      );
      expect(tester.takeException(), isNull);
      // La frase entera: en la lista de una columna cabe.
      expect(find.bySemanticsLabel(RegExp('Próxima clase:')), findsOneWidget);
      expect(find.textContaining('Aula 2.3'), findsOneWidget);
    },
  );

  testWidgets(
    'la próxima clase de hoy dice «Hoy · 17:00» y la de mañana «Mañana» '
    '(como Inicio y Calendario), no el día de la semana',
    (tester) async {
      final now = DateTime.now();
      Subject withClass(DateTime at, int days) => Subject(
        id: 's4',
        name: 'Bases de datos',
        credits: 6,
        perceivedDifficulty: 3,
        priority: SubjectPriority.medium,
        archived: false,
        noteCount: 0,
        fileCount: 0,
        nextUp: SubjectNextUp(
          kind: SubjectNextUpKind.classSession,
          at: at,
          place: 'Aula 2.4',
          daysLeft: days,
          urgent: false,
        ),
      );
      final today = DateTime(now.year, now.month, now.day, 17);
      await _pump(
        tester,
        SubjectCard(subject: withClass(today, 0), onTap: () {}),
      );
      expect(tester.takeException(), isNull);
      expect(
        find.text('Próxima clase: Hoy · 17:00 · Aula 2.4'),
        findsOneWidget,
      );

      final tomorrow = DateTime(now.year, now.month, now.day + 1, 9);
      await _pump(
        tester,
        SubjectCard(subject: withClass(tomorrow, 1), onTap: () {}),
      );
      expect(
        find.text('Próxima clase: Mañana · 9:00 · Aula 2.4'),
        findsOneWidget,
      );
    },
  );

  for (final (width, scale) in [(390.0, 1.0), (320.0, 2.0)]) {
    testWidgets(
      '«Sin temario: importa la guía» empieza donde el texto de la tarjeta, '
      'no encima de la franja (${width.toInt()} dp, ${(scale * 100).toInt()} %)',
      (tester) async {
        await _pump(
          tester,
          SubjectCard(
            subject: const Subject(
              id: 's5',
              name: 'Cálculo',
              credits: 6,
              perceivedDifficulty: 3,
              priority: SubjectPriority.medium,
              archived: false,
              noteCount: 0,
              fileCount: 0,
            ),
            onTap: () {},
            onImportGuide: () {},
          ),
          width: width,
          scale: scale,
        );
        expect(tester.takeException(), isNull);
        final button = tester.getRect(find.byType(FilledButton));
        final name = tester.getRect(find.text('Cálculo'));
        final card = tester.getRect(find.byType(Card));
        // Mismo margen izquierdo que el nombre y dentro de la tarjeta.
        expect(button.left, moreOrLessEquals(name.left, epsilon: 0.5));
        expect(button.right, lessThanOrEqualTo(card.right));
        expect(button.bottom, lessThanOrEqualTo(card.bottom));
      },
    );
  }

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
