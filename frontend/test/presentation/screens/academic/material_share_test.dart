import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart' hide Visibility;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/domain/enums/visibility.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/academic/material_sharing.dart';
import 'package:synaptixfit/domain/models/academic/study_document.dart';
import 'package:synaptixfit/domain/models/academic/subject_material.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/use_cases/academic/get_material_file_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/save_file_to_device_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/send_note_to_friend_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/share_file_outside_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/share_note_on_wall_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/share_note_with_everyone_use_case.dart';
import 'package:synaptixfit/presentation/l10n/gen_l10n/app_localizations.dart';
import 'package:synaptixfit/presentation/screens/academic/material_share/bloc/material_share_bloc.dart';
import 'package:synaptixfit/presentation/screens/academic/material_share/page/material_share_sheet.dart';
import 'package:synaptixfit/presentation/screens/academic/subject_detail/bloc/subject_detail_bloc.dart';
import 'package:synaptixfit/presentation/screens/academic/subject_detail/bloc/subject_progress_bloc.dart';
import 'package:synaptixfit/presentation/screens/academic/subject_detail/bloc/subject_syllabus_bloc.dart';
import 'package:synaptixfit/presentation/screens/academic/subject_detail/page/syllabus_tab.dart';
import 'package:synaptixfit/presentation/screens/academic/widgets/academic_widgets.dart';
import 'package:synaptixfit/presentation/theme/app_theme.dart';

import 'academic_fixtures.dart';

class _Send extends Mock implements SendNoteToFriendUseCaseContract {}

class _Everyone extends Mock implements ShareNoteWithEveryoneUseCaseContract {}

class _Wall extends Mock implements ShareNoteOnWallUseCaseContract {}

class _GetFile extends Mock implements GetMaterialFileUseCaseContract {}

class _Outside extends Mock implements ShareFileOutsideUseCaseContract {}

class _Save extends Mock implements SaveFileToDeviceUseCaseContract {}

class _Share extends MockBloc<MaterialShareEvent, MaterialShareState>
    implements MaterialShareBloc {}

class _Syllabus extends MockBloc<SubjectSyllabusEvent, SubjectSyllabusState>
    implements SubjectSyllabusBloc {}

class _Detail extends MockBloc<SubjectDetailEvent, SubjectDetailState>
    implements SubjectDetailBloc {}

class _Progress extends MockBloc<SubjectProgressEvent, SubjectProgressState>
    implements SubjectProgressBloc {}

final _pdf = MaterialFile(
  fileName: 'Límites.pdf',
  mimeType: 'application/pdf',
  bytes: Uint8List(4),
);

const _noteMaterial = NoteMaterial(note);
const _fileMaterial = FileMaterial(file);

Widget _app(Widget home, {double scale = 1}) => MaterialApp(
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
  home: home,
);

/// «Material» y «Compartir» (ADR 0064): el bloc de compartir, la hoja, sus
/// avisos con «Ver», la lista única y el texto del apunte seleccionable.
void main() {
  setUpAll(() {
    initializeDateFormatting('es');
    registerFallbackValue(_pdf);
    registerFallbackValue(_noteMaterial);
    registerFallbackValue(const MaterialShareEvent.retryRequested());
  });

  group('MaterialShareBloc', () {
    late _Send send;
    late _Everyone everyone;
    late _Wall wall;
    late _GetFile getFile;
    late _Outside outside;
    late _Save save;

    setUp(() {
      send = _Send();
      everyone = _Everyone();
      wall = _Wall();
      getFile = _GetFile();
      outside = _Outside();
      save = _Save();
    });

    MaterialShareBloc build() => MaterialShareBloc(
      sendToFriend: send,
      shareWithEveryone: everyone,
      shareOnWall: wall,
      getFile: getFile,
      shareOutside: outside,
      saveFile: save,
    );

    blocTest<MaterialShareBloc, MaterialShareState>(
      'con un amigo: dice a quién se pasó',
      setUp: () => when(() => send('n1', 'u2')).thenAnswer(
        (_) async => const Success(SentNote(friendId: 'u2', friendName: 'Bea')),
      ),
      build: build,
      act: (bloc) => bloc.add(
        const MaterialShareEvent.friendChosen(
          material: _noteMaterial,
          friendId: 'u2',
        ),
      ),
      expect: () => const [
        MaterialShareState(running: MaterialShareAction.friend),
        MaterialShareState(
          result: MaterialShareResult(
            action: MaterialShareAction.friend,
            materialId: 'n1',
            friendName: 'Bea',
          ),
          seq: 1,
        ),
      ],
    );

    blocTest<MaterialShareBloc, MaterialShareState>(
      'para todos: la visibilidad con la que quedó (la rebaja el servidor)',
      setUp: () => when(() => everyone('n1')).thenAnswer(
        (_) async => Success(note.copyWith(visibility: Visibility.friends)),
      ),
      build: build,
      act: (bloc) =>
          bloc.add(const MaterialShareEvent.everyoneRequested(_noteMaterial)),
      skip: 1,
      expect: () => const [
        MaterialShareState(
          result: MaterialShareResult(
            action: MaterialShareAction.everyone,
            materialId: 'n1',
            visibility: Visibility.friends,
          ),
          seq: 1,
        ),
      ],
    );

    blocTest<MaterialShareBloc, MaterialShareState>(
      'en el muro: si ya estaba, lo dice; un error llega como error',
      setUp: () {
        when(() => wall('n1')).thenAnswer(
          (_) async => const Success(
            NoteWallShare(alreadyShared: true, visibility: Visibility.public),
          ),
        );
      },
      build: build,
      act: (bloc) async {
        bloc.add(const MaterialShareEvent.wallRequested(_noteMaterial));
        await Future<void>.delayed(Duration.zero);
        when(
          () => wall('n1'),
        ).thenAnswer((_) async => const Failure(AppError.network()));
        bloc.add(const MaterialShareEvent.wallRequested(_noteMaterial));
      },
      verify: (bloc) {
        expect(bloc.state.error, const AppError.network());
        expect(bloc.state.seq, 2);
      },
    );

    blocTest<MaterialShareBloc, MaterialShareState>(
      'un archivo no se comparte dentro de la app',
      build: build,
      act: (bloc) {
        bloc
          ..add(const MaterialShareEvent.everyoneRequested(_fileMaterial))
          ..add(const MaterialShareEvent.wallRequested(_fileMaterial));
      },
      expect: () => const <MaterialShareState>[],
    );

    blocTest<MaterialShareBloc, MaterialShareState>(
      'fuera de la app: pide el PDF y abre el menú; cerrarlo no es un error',
      setUp: () {
        when(() => getFile(_noteMaterial)).thenAnswer((_) async => Success(_pdf));
        when(() => outside(_pdf)).thenAnswer((_) async => const Success(false));
      },
      build: build,
      act: (bloc) =>
          bloc.add(const MaterialShareEvent.outsideRequested(_noteMaterial)),
      skip: 1,
      expect: () => const [
        MaterialShareState(
          result: MaterialShareResult(
            action: MaterialShareAction.outside,
            materialId: 'n1',
            fileName: 'Límites.pdf',
            completed: false,
          ),
          seq: 1,
        ),
      ],
    );

    blocTest<MaterialShareBloc, MaterialShareState>(
      'descargar guarda el original; si no se puede bajar, el error',
      setUp: () => when(
        () => getFile(_fileMaterial),
      ).thenAnswer((_) async => const Failure(AppError.network())),
      build: build,
      act: (bloc) =>
          bloc.add(const MaterialShareEvent.downloadRequested(_fileMaterial)),
      skip: 1,
      expect: () => const [
        MaterialShareState(
          error: AppError.network(),
          retry: MaterialShareEvent.downloadRequested(_fileMaterial),
          seq: 1,
        ),
      ],
      verify: (_) => verifyNever(() => save(any())),
    );

    blocTest<MaterialShareBloc, MaterialShareState>(
      '«Reintentar» repite lo que falló con el mismo material',
      setUp: () {
        var calls = 0;
        when(() => wall('n1')).thenAnswer((_) async {
          calls++;
          return calls == 1
              ? const Failure(AppError.network())
              : const Success(
                  NoteWallShare(alreadyShared: false, visibility: Visibility.public),
                );
        });
      },
      build: build,
      act: (bloc) async {
        bloc.add(const MaterialShareEvent.wallRequested(_noteMaterial));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const MaterialShareEvent.retryRequested());
      },
      verify: (bloc) {
        verify(() => wall('n1')).called(2);
        expect(bloc.state.error, isNull);
        expect(bloc.state.retry, isNull);
        expect(bloc.state.result?.action, MaterialShareAction.wall);
      },
    );
  });

  group('hoja «Compartir»', () {
    Future<_Share> open(
      WidgetTester tester,
      SubjectMaterial material, {
      double width = 360,
      double scale = 1,
      Visibility? privacy,
    }) async {
      final bloc = _Share();
      when(() => bloc.state).thenReturn(const MaterialShareState());
      when(() => bloc.isClosed).thenReturn(false);
      tester.view.physicalSize = Size(width, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _app(
          BlocProvider<MaterialShareBloc>.value(
            value: bloc,
            child: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () => showMaterialShareSheet(
                      context,
                      material,
                      profilePrivacy: privacy,
                    ),
                    child: const Text('abrir'),
                  ),
                ),
              ),
            ),
          ),
          scale: scale,
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      return bloc;
    }

    testWidgets('un apunte: las cuatro formas y «Descargar» aparte '
        '(320 px y texto al 200 %)', (tester) async {
      final handle = tester.ensureSemantics();
      final bloc = await open(tester, _noteMaterial, width: 320, scale: 2);
      for (final label in [
        'Con un amigo',
        'Para todos',
        'En el muro',
        'Fuera de la app',
        'Descargar',
      ]) {
        expect(find.text(label), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      // Publicar no va en un toque: antes, una confirmación con el alcance.
      await tester.tap(find.text('En el muro'));
      await tester.pumpAndSettle();
      verifyNever(() => bloc.add(any()));
      expect(find.text('¿Publicar en el muro?'), findsOneWidget);
      expect(find.textContaining('quien pueda ver tu perfil'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      await tester.tap(find.text('Publicar'));
      await tester.pumpAndSettle();
      verify(
        () => bloc.add(const MaterialShareEvent.wallRequested(_noteMaterial)),
      ).called(1);
      handle.dispose();
    });

    testWidgets('«Para todos» dice el alcance según el perfil y se puede '
        'cancelar (320 px y texto al 200 %)', (tester) async {
      final bloc = await open(
        tester,
        _noteMaterial,
        width: 320,
        scale: 2,
        privacy: Visibility.friends,
      );
      await tester.tap(find.text('Para todos'));
      await tester.pumpAndSettle();
      expect(find.text('¿Hacerlo público?'), findsOneWidget);
      expect(find.textContaining('solo lo verán tus amigos'), findsOneWidget);
      expect(find.text('Hacer público'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      verifyNever(() => bloc.add(any()));
    });

    testWidgets('con el perfil privado, «En el muro» no publica y lleva a '
        'Privacidad', (tester) async {
      final bloc = await open(tester, _noteMaterial, privacy: Visibility.private);
      await tester.tap(find.text('En el muro'));
      await tester.pumpAndSettle();
      expect(find.text('Tu perfil es privado'), findsOneWidget);
      expect(find.text('Privacidad'), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      verifyNever(() => bloc.add(any()));
    });

    testWidgets('un archivo: solo fuera de la app, y dice por qué', (
      tester,
    ) async {
      await open(tester, _fileMaterial);
      expect(find.text('Con un amigo'), findsNothing);
      expect(find.text('En el muro'), findsNothing);
      expect(find.text('Fuera de la app'), findsOneWidget);
      expect(find.textContaining('solo se comparte fuera'), findsOneWidget);
      expect(find.text('Descargar'), findsOneWidget);
    });
  });

  group('avisos', () {
    Future<_Share> pumpFeedback(
      WidgetTester tester,
      MaterialShareState result,
    ) async {
      final bloc = _Share();
      whenListen(
        bloc,
        Stream.value(result),
        initialState: const MaterialShareState(),
      );
      await tester.pumpWidget(
        _app(
          BlocProvider<MaterialShareBloc>.value(
            value: bloc,
            child: const MaterialShareFeedback(child: Scaffold()),
          ),
        ),
      );
      await tester.pump();
      return bloc;
    }

    testWidgets('un error lleva «Reintentar», que repite lo mismo', (
      tester,
    ) async {
      final bloc = await pumpFeedback(
        tester,
        const MaterialShareState(
          error: AppError.network(),
          retry: MaterialShareEvent.downloadRequested(_fileMaterial),
          seq: 1,
        ),
      );
      final retry = find.widgetWithText(SnackBarAction, 'Reintentar');
      expect(retry, findsOneWidget);
      tester.widget<SnackBarAction>(retry).onPressed();
      verify(
        () => bloc.add(const MaterialShareEvent.retryRequested()),
      ).called(1);
    });

    testWidgets('el muro rechazado por perfil privado lleva a «Privacidad»', (
      tester,
    ) async {
      await pumpFeedback(
        tester,
        const MaterialShareState(
          error: AppError.business('NOTE_WALL_PROFILE_PRIVATE'),
          seq: 1,
        ),
      );
      expect(find.textContaining('Tu perfil es privado'), findsOneWidget);
      expect(find.widgetWithText(SnackBarAction, 'Privacidad'), findsOneWidget);
    });

    testWidgets('sin nombre del amigo, el aviso no deja un hueco', (
      tester,
    ) async {
      await pumpFeedback(
        tester,
        const MaterialShareState(
          result: MaterialShareResult(
            action: MaterialShareAction.friend,
            materialId: 'n1',
            friendName: ' ',
          ),
          seq: 1,
        ),
      );
      expect(find.text('Enviado: le llega en sus avisos.'), findsOneWidget);
    });

    testWidgets('en el muro: dice dónde quedó y lleva «Ver»', (tester) async {
      await pumpFeedback(
        tester,
        const MaterialShareState(
          result: MaterialShareResult(
            action: MaterialShareAction.wall,
            materialId: 'n1',
            visibility: Visibility.public,
          ),
          seq: 1,
        ),
      );
      expect(find.text('Publicado en el muro.'), findsOneWidget);
      expect(find.widgetWithText(SnackBarAction, 'Ver'), findsOneWidget);
    });

    testWidgets('con un perfil privado lo dice y lleva a la privacidad', (
      tester,
    ) async {
      await pumpFeedback(
        tester,
        const MaterialShareState(
          result: MaterialShareResult(
            action: MaterialShareAction.everyone,
            materialId: 'n1',
            visibility: Visibility.private,
          ),
          seq: 1,
        ),
      );
      expect(find.textContaining('Tu perfil es privado'), findsOneWidget);
      expect(find.widgetWithText(SnackBarAction, 'Privacidad'), findsOneWidget);
    });

    testWidgets('cerrar el menú del sistema no avisa', (tester) async {
      await pumpFeedback(
        tester,
        const MaterialShareState(
          result: MaterialShareResult(
            action: MaterialShareAction.outside,
            materialId: 'n1',
            completed: false,
          ),
          seq: 1,
        ),
      );
      expect(find.byType(SnackBar), findsNothing);
    });
  });

  group('lista «Material»', () {
    Future<void> pumpTab(
      WidgetTester tester,
      SubjectSyllabusState state, {
      double width = 360,
      double scale = 1,
    }) async {
      final syllabus = _Syllabus();
      final detail = _Detail();
      final progress = _Progress();
      final share = _Share();
      when(() => syllabus.state).thenReturn(state);
      when(
        () => detail.state,
      ).thenReturn(const SubjectDetailState(subjectId: 's1', loading: false));
      when(
        () => progress.state,
      ).thenReturn(const SubjectProgressState(subjectId: 's1', loading: false));
      when(() => share.state).thenReturn(const MaterialShareState());
      tester.view.physicalSize = Size(width, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _app(
          MultiBlocProvider(
            providers: [
              BlocProvider<SubjectSyllabusBloc>.value(value: syllabus),
              BlocProvider<SubjectDetailBloc>.value(value: detail),
              BlocProvider<SubjectProgressBloc>.value(value: progress),
              BlocProvider<MaterialShareBloc>.value(value: share),
            ],
            child: const Scaffold(body: SyllabusTab()),
          ),
          scale: scale,
        ),
      );
      await tester.pump();
    }

    testWidgets('apuntes y archivos juntos, cada uno dice qué es '
        '(320 px y texto al 200 %)', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpTab(
        tester,
        const SubjectSyllabusState(
          subjectId: 's1',
          loading: false,
          notes: [note],
          files: [file],
          availability: {
            'n1': DocumentAvailability(
              summary: true,
              mindMap: false,
              practice: false,
            ),
          },
        ),
        width: 320,
        scale: 2,
      );
      expect(find.text('Material (2)'), findsOneWidget);
      expect(find.textContaining('Apunte'), findsWidgets);
      expect(find.textContaining('PDF'), findsWidgets);
      expect(find.text('Límites'), findsOneWidget);
      expect(find.text('guia.pdf'), findsOneWidget);
      // El documento guardado y «Desde una foto» son botones que el lector
      // puede pulsar (el nodo que los nombra lleva la acción).
      expect(
        tester.getSemantics(find.bySemanticsLabel('Resumen de «Límites»')),
        isSemantics(isButton: true, hasTapAction: true),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Nuevo apunte desde una foto')),
        isSemantics(isButton: true, hasTapAction: true),
      );
      // Sin sitio para su texto, «Acciones» es un icono con su nombre.
      expect(find.byTooltip('Acciones de «Límites»'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });

    testWidgets('«Acciones» abre la hoja con eliminar en rojo y aparte', (
      tester,
    ) async {
      await pumpTab(
        tester,
        const SubjectSyllabusState(
          subjectId: 's1',
          loading: false,
          notes: [note],
        ),
      );
      // Con sitio, «Acciones» lleva su texto.
      expect(find.text('Acciones'), findsOneWidget);
      await tester.tap(find.text('Acciones'));
      await tester.pumpAndSettle();
      for (final label in [
        'Abrir',
        'Repasar',
        'Practicar',
        'Compartir',
        'Descargar',
      ]) {
        expect(find.text(label), findsOneWidget);
      }
      final delete = tester.widget<ListTile>(
        find.ancestor(
          of: find.text('Eliminar «Límites»'),
          matching: find.byType(ListTile),
        ),
      );
      expect(delete.textColor, AppTheme.light.colorScheme.error);
    });

    testWidgets('sin material: el estado vacío con las tres formas de añadir', (
      tester,
    ) async {
      await pumpTab(
        tester,
        const SubjectSyllabusState(subjectId: 's1', loading: false),
      );
      expect(find.text('Aún no hay material'), findsOneWidget);
      expect(find.text('Nuevo apunte'), findsOneWidget);
      expect(find.text('Desde una foto'), findsOneWidget);
      expect(find.text('Subir archivo'), findsOneWidget);
    });
  });

  testWidgets('el apunte se selecciona entero con un solo SelectionArea', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const Scaffold(
          body: SingleChildScrollView(
            child: AcademicMarkdown(data: '# Tema\n\nUno\n\n- dos\n- tres'),
          ),
        ),
      ),
    );
    expect(find.byType(SelectionArea), findsOneWidget);
    expect(find.byType(SelectableText), findsNothing);
    expect(find.text('Tema'), findsOneWidget);
  });
}
