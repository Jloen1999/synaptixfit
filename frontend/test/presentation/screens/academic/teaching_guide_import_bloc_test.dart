import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/domain/enums/teaching_guide_import_status.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/academic/subject_file.dart';
import 'package:synaptixfit/domain/models/academic/teaching_guide.dart';
import 'package:synaptixfit/domain/models/academic/teaching_guide_import.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/use_cases/academic/apply_teaching_guide_import_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/await_teaching_guide_import_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/discard_teaching_guide_import_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/retry_teaching_guide_import_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/start_teaching_guide_import_use_case.dart';
import 'package:synaptixfit/presentation/screens/academic/teaching_guide_import/bloc/teaching_guide_import_bloc.dart';

class _Start extends Mock implements StartTeachingGuideImportUseCaseContract {}

class _Await extends Mock implements AwaitTeachingGuideImportUseCaseContract {}

class _Retry extends Mock implements RetryTeachingGuideImportUseCaseContract {}

class _Apply extends Mock implements ApplyTeachingGuideImportUseCaseContract {}

class _Discard extends Mock
    implements DiscardTeachingGuideImportUseCaseContract {}

void main() {
  final payload = FileUploadPayload(
    fileName: 'plan.pdf',
    mimeType: 'application/pdf',
    bytes: Uint8List(3),
  );
  const pending = TeachingGuideImport(
    id: 'i1',
    status: TeachingGuideImportStatus.pending,
    fileName: 'plan.pdf',
  );
  const draft = GuideDraft(info: SubjectGuideInfo(name: 'Hardware'));
  const ready = TeachingGuideImport(
    id: 'i1',
    status: TeachingGuideImportStatus.ready,
    fileName: 'plan.pdf',
    suggestedSubjectId: 's1',
    suggestedSubjectName: 'Hardware',
    draft: draft,
  );
  const failed = TeachingGuideImport(
    id: 'i1',
    status: TeachingGuideImportStatus.failed,
    errorCode: 'AI_QUOTA_EXCEEDED',
    fileName: 'plan.pdf',
  );

  late _Start start;
  late _Await wait;
  late _Retry retry;
  late _Apply apply;
  late _Discard discard;

  setUpAll(() {
    registerFallbackValue(payload);
    registerFallbackValue(draft);
  });

  setUp(() {
    start = _Start();
    wait = _Await();
    retry = _Retry();
    apply = _Apply();
    discard = _Discard();
    when(
      () => start(
        any(),
        targetSubjectId: any(named: 'targetSubjectId'),
        onProgress: any(named: 'onProgress'),
      ),
    ).thenAnswer((_) async => const Success(pending));
  });

  TeachingGuideImportBloc build() => TeachingGuideImportBloc(
    start: start,
    await: wait,
    retry: retry,
    apply: apply,
    discard: discard,
  );

  blocTest<TeachingGuideImportBloc, TeachingGuideImportState>(
    'sube, espera el análisis y propone completar la asignatura que coincide',
    setUp: () => when(() => wait('i1')).thenAnswer(
      (_) => Stream.fromIterable(const [Success(pending), Success(ready)]),
    ),
    build: build,
    act: (bloc) => bloc.add(TeachingGuideImportEvent.filePicked(payload)),
    skip: 1,
    expect: () => const [
      TeachingGuideImportState(
        phase: GuideImportPhase.analyzing,
        guideImport: pending,
        fileName: 'plan.pdf',
      ),
      TeachingGuideImportState(
        phase: GuideImportPhase.review,
        guideImport: ready,
        draft: draft,
        destinationSubjectId: 's1',
        fileName: 'plan.pdf',
      ),
    ],
  );

  blocTest<TeachingGuideImportBloc, TeachingGuideImportState>(
    'un fallo de la IA muestra su código y se puede reintentar',
    setUp: () {
      when(
        () => wait('i1'),
      ).thenAnswer((_) => Stream.value(const Success(failed)));
      when(() => retry('i1')).thenAnswer((_) async => const Success(pending));
    },
    build: build,
    act: (bloc) async {
      bloc.add(TeachingGuideImportEvent.filePicked(payload));
      await Future<void>.delayed(Duration.zero);
      when(
        () => wait('i1'),
      ).thenAnswer((_) => Stream.value(const Success(ready)));
      bloc.add(const TeachingGuideImportEvent.retried());
    },
    skip: 2,
    expect: () => [
      const TeachingGuideImportState(
        phase: GuideImportPhase.failed,
        guideImport: failed,
        error: AppError.business('AI_QUOTA_EXCEEDED'),
        fileName: 'plan.pdf',
      ),
      isA<TeachingGuideImportState>().having(
        (s) => s.phase,
        'phase',
        GuideImportPhase.analyzing,
      ),
      isA<TeachingGuideImportState>().having(
        (s) => s.phase,
        'phase',
        GuideImportPhase.analyzing,
      ),
      isA<TeachingGuideImportState>().having(
        (s) => s.phase,
        'phase',
        GuideImportPhase.review,
      ),
    ],
  );

  blocTest<TeachingGuideImportBloc, TeachingGuideImportState>(
    'aplicar crea la asignatura nueva si se elige y termina en «listo»',
    setUp: () =>
        when(
          () =>
              apply('i1', subjectId: null, draft: draft, createDeadlines: true),
        ).thenAnswer(
          (_) async => const Success(
            TeachingGuideImportResult(
              subjectId: 's2',
              subjectCreated: true,
              deadlinesRequested: 1,
            ),
          ),
        ),
    build: build,
    seed: () => const TeachingGuideImportState(
      phase: GuideImportPhase.review,
      guideImport: ready,
      draft: draft,
      destinationSubjectId: 's1',
    ),
    act: (bloc) => bloc
      ..add(const TeachingGuideImportEvent.destinationChanged(null))
      ..add(const TeachingGuideImportEvent.applied()),
    skip: 2,
    expect: () => [
      isA<TeachingGuideImportState>()
          .having((s) => s.phase, 'phase', GuideImportPhase.done)
          .having((s) => s.result?.subjectId, 'subjectId', 's2'),
    ],
  );

  blocTest<TeachingGuideImportBloc, TeachingGuideImportState>(
    'elegir otro PDF descarta la importación y vuelve al principio',
    setUp: () =>
        when(() => discard('i1')).thenAnswer((_) async => const Success(unit)),
    build: build,
    seed: () => const TeachingGuideImportState(
      phase: GuideImportPhase.review,
      targetSubjectId: 's9',
      guideImport: ready,
      draft: draft,
    ),
    act: (bloc) => bloc.add(const TeachingGuideImportEvent.restarted()),
    expect: () => const [TeachingGuideImportState(targetSubjectId: 's9')],
    verify: (_) => verify(() => discard('i1')).called(1),
  );
}
