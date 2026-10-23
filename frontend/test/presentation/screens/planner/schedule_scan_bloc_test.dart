import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/domain/enums/planner_enums.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/planner/planner_ai.dart';
import 'package:synaptixfit/domain/models/planner/planner_options.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/use_cases/planner/export_ics_use_case.dart';
import 'package:synaptixfit/domain/use_cases/planner/get_planner_subjects_use_case.dart';
import 'package:synaptixfit/domain/use_cases/planner/import_ics_use_case.dart';
import 'package:synaptixfit/domain/use_cases/planner/save_semester_dates_use_case.dart';
import 'package:synaptixfit/domain/use_cases/planner/scan_schedule_use_case.dart';
import 'package:synaptixfit/presentation/screens/planner/schedule_scan/bloc/schedule_scan_bloc.dart';

import 'planner_fixtures.dart';

class _Subjects extends Mock implements GetPlannerSubjectsUseCaseContract {}

class _Scan extends Mock implements ScanScheduleUseCaseContract {}

class _Dates extends Mock implements SaveSemesterDatesUseCaseContract {}

class _Import extends Mock implements ImportIcsUseCaseContract {}

class _Export extends Mock implements ExportIcsUseCaseContract {}

void main() {
  setUpAll(registerPlannerFallbacks);

  late _Subjects getSubjects;
  late _Scan scan;
  late _Dates saveDates;
  late _Import importIcs;
  late _Export exportIcs;

  const file = ScheduleFile(
    name: 'horario.pdf',
    bytes: [1, 2, 3],
    mimeType: 'application/pdf',
  );
  const result = ScheduleScanResult(
    classesFound: 5,
    blocksCreated: 60,
    blocksUpdated: 0,
    unmatchedSubjects: ['Inglés'],
  );
  const missing = AppError.business('SCHEDULE_SEMESTER_DATES_MISSING');

  ScheduleScanBloc build() => ScheduleScanBloc(
    getSubjects: getSubjects,
    scanSchedule: scan,
    saveSemesterDates: saveDates,
    importIcs: importIcs,
    exportIcs: exportIcs,
  );

  setUp(() {
    getSubjects = _Subjects();
    scan = _Scan();
    saveDates = _Dates();
    importIcs = _Import();
    exportIcs = _Export();
  });

  blocTest<ScheduleScanBloc, ScheduleScanState>(
    'carga las asignaturas para el ICS',
    setUp: () => when(() => getSubjects()).thenAnswer(
      (_) async => const Success([SubjectOption(id: 's1', name: 'Física')]),
    ),
    build: build,
    act: (bloc) => bloc.add(const ScheduleScanEvent.started()),
    expect: () => [
      isA<ScheduleScanState>()
          .having((s) => s.subjectsLoaded, 'loaded', isTrue)
          .having((s) => s.subjects.length, 'subjects', 1),
    ],
  );

  blocTest<ScheduleScanBloc, ScheduleScanState>(
    'sin fechas de semestre las pide, las guarda y reintenta el escaneo',
    setUp: () {
      var calls = 0;
      when(() => scan(any(), onProgress: any(named: 'onProgress'))).thenAnswer(
        (_) async =>
            calls++ == 0 ? const Failure(missing) : const Success(result),
      );
      when(
        () => saveDates(
          start: any(named: 'start'),
          end: any(named: 'end'),
        ),
      ).thenAnswer((_) async => const Success(unit));
    },
    build: build,
    act: (bloc) async {
      bloc.add(const ScheduleScanEvent.fileSelected(file));
      await bloc.stream.firstWhere(
        (s) => s.scanStatus == ScanStatus.needsSemesterDates,
      );
      bloc.add(
        ScheduleScanEvent.semesterDatesSubmitted(
          start: DateTime(2025, 9, 15),
          end: DateTime(2026, 1, 23),
        ),
      );
    },
    verify: (bloc) {
      expect(bloc.state.scanStatus, ScanStatus.done);
      expect(bloc.state.scanResult, result);
      expect(bloc.state.notice, const ScheduleScanNotice.scanned(result));
      verify(
        () =>
            saveDates(start: DateTime(2025, 9, 15), end: DateTime(2026, 1, 23)),
      ).called(1);
      verify(() => scan(file, onProgress: any(named: 'onProgress'))).called(2);
    },
  );

  blocTest<ScheduleScanBloc, ScheduleScanState>(
    'otros errores del escaneo se muestran en la tarjeta',
    setUp: () => when(() => scan(any(), onProgress: any(named: 'onProgress')))
        .thenAnswer(
          (_) async =>
              const Failure(AppError.business('SCHEDULE_FILE_TOO_LARGE')),
        ),
    build: build,
    act: (bloc) => bloc.add(const ScheduleScanEvent.fileSelected(file)),
    skip: 1,
    expect: () => [
      isA<ScheduleScanState>()
          .having((s) => s.scanStatus, 'status', ScanStatus.idle)
          .having(
            (s) => s.scanError,
            'error',
            const AppError.business('SCHEDULE_FILE_TOO_LARGE'),
          ),
    ],
  );

  blocTest<ScheduleScanBloc, ScheduleScanState>(
    'importa un ICS y recuerda la petición para forzarla',
    setUp: () =>
        when(
          () => importIcs(
            subjectId: 's1',
            url: 'https://campus/x.ics',
            force: false,
          ),
        ).thenAnswer(
          (_) async => const Success(
            IcsImportResult(
              match: IcsMatch.partial,
              totalEvents: 10,
              matchingEvents: 3,
              classes: 0,
              exams: 0,
              deliveries: 0,
              created: 0,
              updated: 0,
              imported: false,
            ),
          ),
        ),
    build: build,
    act: (bloc) => bloc.add(
      const ScheduleScanEvent.icsImportRequested(
        subjectId: 's1',
        url: 'https://campus/x.ics',
      ),
    ),
    skip: 1,
    expect: () => [
      isA<ScheduleScanState>()
          .having((s) => s.importingIcs, 'importing', isFalse)
          .having((s) => s.icsResult?.imported, 'imported', isFalse)
          .having((s) => s.icsSubjectId, 'subject', 's1')
          .having((s) => s.icsUrl, 'url', 'https://campus/x.ics'),
    ],
  );

  blocTest<ScheduleScanBloc, ScheduleScanState>(
    'exportar entrega el contenido .ics a la página',
    setUp: () => when(
      () => exportIcs(),
    ).thenAnswer((_) async => const Success('BEGIN:VCALENDAR')),
    build: build,
    act: (bloc) => bloc.add(const ScheduleScanEvent.exportRequested()),
    expect: () => [
      isA<ScheduleScanState>().having((s) => s.exporting, 'exporting', isTrue),
      isA<ScheduleScanState>()
          .having((s) => s.exporting, 'exporting', isFalse)
          .having(
            (s) => s.notice,
            'notice',
            const ScheduleScanNotice.exportReady('BEGIN:VCALENDAR'),
          ),
    ],
  );
}
