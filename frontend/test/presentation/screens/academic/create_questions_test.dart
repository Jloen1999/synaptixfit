import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/app/di/app_di.dart';
import 'package:synaptixfit/domain/enums/question_creation_enums.dart';
import 'package:synaptixfit/domain/enums/question_type.dart';
import 'package:synaptixfit/domain/enums/study_source_type.dart';
import 'package:synaptixfit/domain/enums/visibility.dart' as vis;
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/academic/note.dart';
import 'package:synaptixfit/domain/models/academic/question_creation.dart';
import 'package:synaptixfit/domain/models/academic/quiz.dart';
import 'package:synaptixfit/domain/models/result/app_result.dart';
import 'package:synaptixfit/domain/models/academic/subject_file.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/use_cases/academic/generate_question_bank_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/get_notes_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/get_question_bank_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/get_subject_files_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/register_study_material_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/scan_document_questions_use_case.dart';
import 'package:synaptixfit/presentation/l10n/gen_l10n/app_localizations.dart';
import 'package:synaptixfit/presentation/screens/academic/create_questions/bloc/create_questions_bloc.dart';
import 'package:synaptixfit/presentation/screens/academic/create_questions/page/create_questions_sheet.dart';
import 'package:synaptixfit/presentation/screens/academic/widgets/question_view.dart';
import 'package:synaptixfit/presentation/theme/app_theme.dart';

import 'academic_fixtures.dart';

class _GetNotes extends Mock implements GetNotesUseCaseContract {}

class _GetFiles extends Mock implements GetSubjectFilesUseCaseContract {}

class _Register extends Mock implements RegisterStudyMaterialUseCaseContract {}

class _GetBank extends Mock implements GetQuestionBankUseCaseContract {}

class _Scan extends Mock implements ScanDocumentQuestionsUseCaseContract {}

class _Generate extends Mock implements GenerateQuestionBankUseCaseContract {}

const _ready = DocumentQuestion(
  type: QuestionType.multipleChoice,
  statement: '¿Qué cláusula filtra los grupos?',
  options: ['WHERE', 'HAVING', 'ORDER BY'],
  correctAnswers: ['HAVING'],
  status: DocumentQuestionStatus.ready,
);

const _proposed = DocumentQuestion(
  type: QuestionType.fillInBlank,
  statement: 'Una clave ____ identifica cada fila.',
  correctAnswers: ['primaria'],
  status: DocumentQuestionStatus.answerProposed,
);

const _long = DocumentQuestion(
  statement: 'Explica la diferencia entre DELETE y TRUNCATE.',
  status: DocumentQuestionStatus.longAnswer,
);

const _scan = DocumentQuestionScan(questions: [_ready, _proposed, _long]);

/// «Crear preguntas» y «Revisa las de tu apunte» (ADR 0058).
void main() {
  late _GetNotes getNotes;
  late _GetFiles getFiles;
  late _Register register;
  late _GetBank getBank;
  late _Scan scan;
  late _Generate generate;

  setUpAll(() {
    registerFallbackValue(
      const CreateQuestionsRequest(
        format: QuestionFormat.mixed,
        newQuestions: 0,
        mode: BankUpdateMode.add,
      ),
    );
    registerFallbackValue(StudySourceType.note);
  });

  setUp(() {
    getNotes = _GetNotes();
    getFiles = _GetFiles();
    register = _Register();
    getBank = _GetBank();
    scan = _Scan();
    generate = _Generate();
    when(() => getBank('m1')).thenAnswer((_) async => const Success(null));
    when(() => scan('m1')).thenAnswer((_) async => const Success(_scan));
    when(
      () => generate('m1', any()),
    ).thenAnswer((_) async => const Success(bank));
  });

  CreateQuestionsBloc build() => CreateQuestionsBloc(
    getNotes: getNotes,
    getFiles: getFiles,
    registerMaterial: register,
    getBank: getBank,
    scan: scan,
    generate: generate,
  );

  Future<CreateQuestionsBloc> started({String? subjectId}) async {
    final bloc = build()
      ..add(
        subjectId == null
            ? const CreateQuestionsEvent.started(materialId: 'm1', title: 'SQL')
            : CreateQuestionsEvent.started(subjectId: subjectId),
      );
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    return bloc;
  }

  CreateQuestionsRequest lastRequest() =>
      verify(() => generate('m1', captureAny())).captured.last
          as CreateQuestionsRequest;

  group('CreateQuestionsBloc', () {
    test(
      'sin preguntas en el documento crea directamente las pedidas',
      () async {
        when(
          () => scan('m1'),
        ).thenAnswer((_) async => const Success(DocumentQuestionScan()));
        final bloc = await started();
        expect(bloc.state.showsDocumentChoice, isFalse);
        expect(bloc.state.showsModeChoice, isFalse);

        bloc
          ..add(const CreateQuestionsEvent.countChanged(20))
          ..add(const CreateQuestionsEvent.submitted());
        await Future<void>.delayed(Duration.zero);

        final request = lastRequest();
        expect(request.newQuestions, 20);
        expect(request.documentQuestions, isEmpty);
        expect(bloc.state.saved, bank);
        expect(bloc.state.reviewRequest, 0);
      },
    );

    test('la cantidad va de 5 a 30', () async {
      final bloc = await started()
        ..add(const CreateQuestionsEvent.countChanged(35));
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.count, QuestionCount.max);
      bloc.add(const CreateQuestionsEvent.countChanged(0));
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.count, QuestionCount.min);
    });

    test('con las que ya tienes pregunta si añadir o cambiar', () async {
      when(() => getBank('m1')).thenAnswer((_) async => const Success(bank));
      final bloc = await started()
        ..add(const CreateQuestionsEvent.modeChosen(BankUpdateMode.replace))
        ..add(
          const CreateQuestionsEvent.documentUseChosen(
            DocumentQuestionUse.none,
          ),
        )
        ..add(const CreateQuestionsEvent.submitted());
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.existingCount, 2);
      expect(lastRequest().mode, BankUpdateMode.replace);
    });

    test('mezclar: revisar, quitar una y cambiar la respuesta', () async {
      final bloc = await started()
        ..add(const CreateQuestionsEvent.submitted());
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.reviewRequest, 1);
      // La de respuesta larga no se marca: no se puede corregir sola.
      expect(bloc.state.used, {0, 1});
      expect(bloc.state.newCount, 8);
      expect(bloc.state.totalToSave, 10);

      bloc
        ..add(const CreateQuestionsEvent.reviewToggled(2))
        ..add(const CreateQuestionsEvent.reviewToggled(0))
        ..add(const CreateQuestionsEvent.answerChanged(1, ['candidata']))
        ..add(const CreateQuestionsEvent.saveRequested());
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.used, {1});
      final request = lastRequest();
      expect(request.newQuestions, 9);
      expect(request.documentQuestions.single.correctAnswers, ['candidata']);
    });

    test('usar solo las del documento no crea nuevas', () async {
      final bloc = await started()
        ..add(
          const CreateQuestionsEvent.documentUseChosen(
            DocumentQuestionUse.only,
          ),
        )
        ..add(const CreateQuestionsEvent.submitted())
        ..add(const CreateQuestionsEvent.saveRequested());
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.asksNewQuestions, isFalse);
      final request = lastRequest();
      expect(request.newQuestions, 0);
      expect(request.documentQuestions, hasLength(2));
    });

    test('si la IA falla queda el error y se puede reintentar', () async {
      when(
        () => scan('m1'),
      ).thenAnswer((_) async => const Success(DocumentQuestionScan()));
      when(() => generate('m1', any())).thenAnswer(
        (_) async => const Failure(AppError.business('AI_UNAVAILABLE')),
      );
      final bloc = await started()
        ..add(const CreateQuestionsEvent.submitted());
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.saveError, const AppError.business('AI_UNAVAILABLE'));
      expect(bloc.state.saved, isNull);

      when(
        () => generate('m1', any()),
      ).thenAnswer((_) async => const Success(bank));
      bloc.add(const CreateQuestionsEvent.submitted());
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.saveError, isNull);
      expect(bloc.state.saved, bank);
    });

    test('desde la asignatura con varios apuntes pregunta cuál', () async {
      when(() => getNotes(subjectId: 's1')).thenAnswer(
        (_) async => const Success([
          Note(
            id: 'n1',
            subjectId: 's1',
            title: 'SQL',
            content: '',
            visibility: vis.Visibility.private,
            quickNote: false,
          ),
        ]),
      );
      when(() => getFiles('s1')).thenAnswer(
        (_) async => const Success([
          SubjectFile(
            id: 'f1',
            subjectId: 's1',
            fileName: 'tema4.pdf',
            mimeType: 'application/pdf',
            sizeBytes: 10,
            aiReadable: true,
          ),
          SubjectFile(
            id: 'f2',
            subjectId: 's1',
            fileName: 'audio.mp3',
            mimeType: 'audio/mpeg',
            sizeBytes: 10,
            aiReadable: false,
          ),
        ]),
      );
      when(
        () => register(StudySourceType.file, 'f1'),
      ).thenAnswer((_) async => const Success(material));

      final bloc = await started(subjectId: 's1');
      expect(bloc.state.choosingSource, isTrue);
      expect(bloc.state.sources.map((s) => s.id), ['n1', 'f1']);

      bloc.add(CreateQuestionsEvent.sourceChosen(bloc.state.sources.last));
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.choosingSource, isFalse);
      expect(bloc.state.materialId, 'm1');
      expect(bloc.state.title, 'tema4.pdf');
      expect(bloc.state.scan, _scan);
    });
  });

  group('Hoja y revisión', () {
    setUp(() => getIt.registerFactory<CreateQuestionsBloc>(build));
    tearDown(() => getIt.unregister<CreateQuestionsBloc>());

    Future<void> openSheet(
      WidgetTester tester, {
      String? subjectId,
      bool settle = true,
    }) async {
      tester.view.physicalSize = const Size(420, 1000);
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
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => subjectId != null
                    ? showCreateQuestionsSheet(context, subjectId: subjectId)
                    : showCreateQuestionsSheet(
                        context,
                        materialId: 'm1',
                        title: 'SQL',
                      ),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      if (settle) {
        await tester.pumpAndSettle();
      } else {
        // Los esqueletos se animan: unos fotogramas bastan.
        for (var i = 0; i < 5; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
      }
    }

    testWidgets(
      'cargando los apuntes o preparando, la hoja se pinta sin fallos',
      (tester) async {
        final notes = Completer<AppResult<List<Note>>>();
        when(() => getNotes(subjectId: 's1')).thenAnswer((_) => notes.future);
        when(() => getFiles('s1')).thenAnswer((_) async => const Success([]));
        await openSheet(tester, subjectId: 's1', settle: false);
        expect(tester.takeException(), isNull);
        expect(find.text('Crear preguntas'), findsOneWidget);
        notes.complete(const Success([]));
        await tester.pumpAndSettle();
        // Sin apuntes: lo dice y ofrece crear uno.
        expect(find.text('Aún no hay apuntes'), findsOneWidget);
        expect(find.text('Nuevo apunte'), findsOneWidget);
      },
    );

    testWidgets('mientras lee el banco enseña el esqueleto sin fallos', (
      tester,
    ) async {
      final pending = Completer<AppResult<QuestionBank?>>();
      when(() => getBank('m1')).thenAnswer((_) => pending.future);
      await openSheet(tester, settle: false);
      expect(tester.takeException(), isNull);
      expect(find.text('De: SQL'), findsOneWidget);
      pending.complete(const Success(null));
      await tester.pumpAndSettle();
      expect(find.text('Crear 10 preguntas'), findsOneWidget);
    });

    testWidgets('sin preguntas en el apunte ni previas no pregunta nada más', (
      tester,
    ) async {
      when(
        () => scan('m1'),
      ).thenAnswer((_) async => const Success(DocumentQuestionScan()));
      await openSheet(tester);

      expect(find.text('De: SQL'), findsOneWidget);
      expect(find.text('Mezcla'), findsOneWidget);
      expect(find.textContaining('Tu apunte ya trae'), findsNothing);
      expect(find.textContaining('Ya tienes'), findsNothing);
      expect(find.text('Crear 10 preguntas'), findsOneWidget);
    });

    testWidgets(
      'con preguntas en el apunte y previas, enseña las dos opciones',
      (tester) async {
        when(() => getBank('m1')).thenAnswer((_) async => const Success(bank));
        await openSheet(tester);

        expect(find.text('Tu apunte ya trae 3 preguntas'), findsOneWidget);
        expect(find.text('Mezclarlas con nuevas'), findsOneWidget);
        expect(find.text('Ya tienes 2 de este apunte'), findsOneWidget);
        expect(find.text('Añadir a las que tienes'), findsOneWidget);
        expect(
          find.text('Antes de guardarlas, revisas las de tu apunte.'),
          findsOneWidget,
        );
      },
    );

    testWidgets('la revisión cuenta las del apunte y las nuevas', (
      tester,
    ) async {
      await openSheet(tester);
      await tester.tap(find.text('Crear 10 preguntas'));
      await tester.pumpAndSettle();

      expect(find.text('Revisa las de tu apunte'), findsOneWidget);
      expect(
        find.text('Quita las que no quieras. Usarás 2 de 3.'),
        findsOneWidget,
      );
      expect(find.text('HAVING · correcta'), findsOneWidget);
      expect(
        find.text(
          'Tu apunte no traía la respuesta. Propuesta: «primaria». Revísala.',
        ),
        findsOneWidget,
      );
      expect(
        find.text('No se puede corregir sola: no se usará.'),
        findsOneWidget,
      );
      expect(find.text('Guardar 10 preguntas'), findsOneWidget);
      expect(find.text('2 de tu apunte y 8 nuevas'), findsOneWidget);

      // Quitar la primera: una menos del apunte, una nueva más.
      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();
      expect(
        find.text('Quita las que no quieras. Usarás 1 de 3.'),
        findsOneWidget,
      );
      expect(find.text('1 de tu apunte y 9 nuevas'), findsOneWidget);

      // Cambiar la respuesta de la primera.
      await tester.tap(find.text('Cambiar la respuesta').first);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(RadioListTile<String>, 'WHERE'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      expect(find.text('WHERE · correcta'), findsOneWidget);
      expect(find.text('HAVING · correcta'), findsNothing);

      await tester.tap(find.text('Guardar 10 preguntas'));
      await tester.pumpAndSettle();
      expect(find.text('Revisa las de tu apunte'), findsNothing);
      final request =
          verify(() => generate('m1', captureAny())).captured.last
              as CreateQuestionsRequest;
      expect(request.newQuestions, 9);
      expect(request.documentQuestions.single.statement, _proposed.statement);
    });
  });

  testWidgets('varias correctas: casillas, «Elige todas las correctas» y '
      'corrección con todas las buenas', (tester) async {
    String? answer;
    Widget view({QuestionFeedback? feedback}) => MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('es'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) => QuestionView(
            statement: '¿Cuáles agregan filas?',
            type: QuestionType.multipleAnswer,
            options: const ['COUNT', 'JOIN', 'AVG'],
            answer: answer,
            onAnswerChanged: (v) => setState(() => answer = v),
            feedback: feedback,
          ),
        ),
      ),
    );
    await tester.pumpWidget(view());
    expect(find.text('Elige todas las correctas'), findsOneWidget);
    await tester.tap(find.text('AVG'));
    await tester.pump();
    await tester.tap(find.text('COUNT'));
    await tester.pump();
    // Se guardan en el orden de las opciones.
    expect(answer, 'COUNT\nAVG');
    await tester.tap(find.text('AVG'));
    await tester.pump();
    expect(answer, 'COUNT');

    await tester.pumpWidget(
      view(
        feedback: const QuestionFeedback(
          correct: false,
          correctAnswers: ['COUNT', 'AVG'],
        ),
      ),
    );
    expect(find.text('Respuesta correcta: COUNT · AVG'), findsOneWidget);
  });
}
