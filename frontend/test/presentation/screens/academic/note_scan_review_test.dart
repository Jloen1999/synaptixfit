import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/app/di/app_di.dart';
import 'package:synaptixfit/domain/models/academic/note_scan.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/use_cases/academic/create_note_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/get_subjects_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/read_note_photos_use_case.dart';
import 'package:synaptixfit/presentation/l10n/gen_l10n/app_localizations.dart';
import 'package:synaptixfit/presentation/screens/academic/note_scan/bloc/note_scan_bloc.dart';
import 'package:synaptixfit/presentation/screens/academic/note_scan/page/note_scan_page.dart';
import 'package:synaptixfit/presentation/theme/app_theme.dart';

class _GetSubjects extends Mock implements GetSubjectsUseCaseContract {}

class _ReadPhotos extends Mock implements ReadNotePhotosUseCaseContract {}

class _CreateNote extends Mock implements CreateNoteUseCaseContract {}

/// PNG de 1×1 px: una foto válida y mínima.
final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

final _photo = NotePhotoUpload(
  bytes: _png,
  fileName: 'pagina.png',
  mimeType: 'image/png',
);

/// Paso de revisión (ADR 0051): la foto al lado del texto para comparar y, si
/// el servidor no pudo leerla bien, un aviso claro sin jerga.
void main() {
  late _GetSubjects getSubjects;
  late _ReadPhotos readPhotos;
  late NoteScanBloc bloc;

  setUpAll(() => registerFallbackValue(<NotePhotoUpload>[]));

  setUp(() {
    getSubjects = _GetSubjects();
    readPhotos = _ReadPhotos();
    when(
      () => getSubjects(archived: false),
    ).thenAnswer((_) async => const Success([]));
    getIt.registerFactory<NoteScanBloc>(
      () => bloc = NoteScanBloc(
        getSubjects: getSubjects,
        readPhotos: readPhotos,
        createNote: _CreateNote(),
      ),
    );
  });

  tearDown(() => getIt.unregister<NoteScanBloc>());

  Future<void> reviewWith(WidgetTester tester, ScannedNoteDraft draft) async {
    when(() => readPhotos(any())).thenAnswer((_) async => Success(draft));
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      routes: [GoRoute(path: '/', builder: (_, _) => const NoteScanPage())],
    );
    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.light,
        locale: const Locale('es'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();
    bloc
      ..add(NoteScanEvent.photosAdded([_photo, _photo]))
      ..add(const NoteScanEvent.readRequested());
    await tester.pumpAndSettle();
  }

  testWidgets('una lectura dudosa avisa y enseña las fotos para comparar', (
    tester,
  ) async {
    await reviewWith(
      tester,
      const ScannedNoteDraft(
        markdown: 'Tcma 1 la ce1ula',
        tidied: false,
        pages: 2,
        unclear: true,
      ),
    );

    expect(
      find.text(
        'Parte del texto no se ha leído bien. Compáralo con tus fotos y '
        'escribe lo que falte.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('OCR'), findsNothing);
    expect(find.textContaining('confianza'), findsNothing);
    expect(find.text('Tus fotos'), findsOneWidget);
    expect(find.bySemanticsLabel('Ver la página 2 en grande'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Ver la página 1 en grande'));
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsOneWidget);

    // Ampliar sin pellizcar (WCAG 2.5.1) y pasar de página sin cerrar.
    await tester.tap(find.byTooltip('Acercar'));
    await tester.pumpAndSettle();
    expect(find.text('1 de 2'), findsOneWidget);
    await tester.tap(find.byTooltip('Alejar'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Página siguiente'));
    await tester.pumpAndSettle();
    expect(find.text('2 de 2'), findsOneWidget);

    await tester.tap(find.byTooltip('Cerrar'));
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('con una lectura clara no hay aviso, pero sí las fotos', (
    tester,
  ) async {
    await reviewWith(
      tester,
      const ScannedNoteDraft(
        title: 'La célula',
        markdown: '## La célula',
        tidied: true,
        pages: 2,
      ),
    );

    expect(find.textContaining('No se ha podido leer bien'), findsNothing);
    expect(
      find.text('Revisa que diga lo mismo que tus apuntes.'),
      findsOneWidget,
    );
    expect(find.text('Tus fotos'), findsOneWidget);
  });
}
