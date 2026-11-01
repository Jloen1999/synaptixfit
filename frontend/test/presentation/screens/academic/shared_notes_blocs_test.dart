import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/domain/enums/shared_notes_scope.dart';
import 'package:synaptixfit/domain/enums/visibility.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/academic/note.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/use_cases/academic/copy_shared_note_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/get_shared_note_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/get_shared_notes_use_case.dart';
import 'package:synaptixfit/presentation/screens/academic/shared_note_detail/bloc/shared_note_detail_bloc.dart';
import 'package:synaptixfit/presentation/screens/academic/shared_notes/bloc/shared_notes_bloc.dart';

class _GetShared extends Mock implements GetSharedNotesUseCaseContract {}

class _GetNote extends Mock implements GetSharedNoteUseCaseContract {}

class _Copy extends Mock implements CopySharedNoteUseCaseContract {}

const _summary = SharedNoteSummary(
  id: 'n1',
  authorId: 'u2',
  authorName: 'Luis Gil',
  title: 'Normalización',
  excerpt: 'Primera forma normal',
  visibility: Visibility.friends,
);

const _note = SharedNote(
  id: 'n1',
  authorId: 'u2',
  authorName: 'Luis Gil',
  title: 'Normalización',
  content: '# 1FN',
  visibility: Visibility.friends,
);

const _copy = Note(
  id: 'c1',
  title: 'Normalización',
  content: '# 1FN',
  visibility: Visibility.private,
  quickNote: false,
);

void main() {
  setUpAll(() => registerFallbackValue(SharedNotesScope.all));

  group('SharedNotesBloc', () {
    late _GetShared getShared;

    setUp(() => getShared = _GetShared());

    blocTest<SharedNotesBloc, SharedNotesState>(
      'pide los apuntes del ámbito de su pestaña',
      setUp: () =>
          when(
            () => getShared(
              page: 0,
              scope: SharedNotesScope.friends,
              authorId: any(named: 'authorId'),
              size: any(named: 'size'),
            ),
          ).thenAnswer(
            (_) async => const Success(
              SharedNoteSummaryPage(items: [_summary], page: 0, totalPages: 1),
            ),
          ),
      build: () => SharedNotesBloc(getShared: getShared),
      act: (bloc) => bloc.add(
        const SharedNotesEvent.started(scope: SharedNotesScope.friends),
      ),
      expect: () => const [
        SharedNotesState(scope: SharedNotesScope.friends),
        SharedNotesState(
          scope: SharedNotesScope.friends,
          loading: false,
          items: [_summary],
        ),
      ],
    );

    blocTest<SharedNotesBloc, SharedNotesState>(
      'un error sin datos se muestra con reintento',
      setUp: () => when(
        () => getShared(
          page: 0,
          scope: any(named: 'scope'),
          authorId: 'u2',
          size: any(named: 'size'),
        ),
      ).thenAnswer((_) async => const Failure(AppError.network())),
      build: () => SharedNotesBloc(getShared: getShared),
      act: (bloc) => bloc.add(const SharedNotesEvent.started(authorId: 'u2')),
      expect: () => const [
        SharedNotesState(authorId: 'u2'),
        SharedNotesState(
          authorId: 'u2',
          loading: false,
          error: AppError.network(),
        ),
      ],
    );
  });

  group('SharedNotesBloc paginación', () {
    late _GetShared getShared;

    setUp(() => getShared = _GetShared());

    blocTest<SharedNotesBloc, SharedNotesState>(
      'si falla la página siguiente guarda el error y no da la lista por acabada',
      setUp: () => when(
        () => getShared(
          page: 1,
          scope: any(named: 'scope'),
          authorId: any(named: 'authorId'),
          size: any(named: 'size'),
        ),
      ).thenAnswer((_) async => const Failure(AppError.network())),
      build: () => SharedNotesBloc(getShared: getShared),
      seed: () => const SharedNotesState(
        loading: false,
        items: [_summary],
        hasMore: true,
      ),
      act: (bloc) => bloc.add(const SharedNotesEvent.moreRequested()),
      expect: () => const [
        SharedNotesState(
          loading: false,
          items: [_summary],
          hasMore: true,
          loadingMore: true,
        ),
        SharedNotesState(
          loading: false,
          items: [_summary],
          hasMore: true,
          loadMoreError: AppError.network(),
        ),
      ],
    );
  });

  group('SharedNoteDetailBloc', () {
    late _GetNote getNote;
    late _Copy copy;

    setUp(() {
      getNote = _GetNote();
      copy = _Copy();
      when(() => getNote('n1')).thenAnswer((_) async => const Success(_note));
    });

    blocTest<SharedNoteDetailBloc, SharedNoteDetailState>(
      'guarda una copia y avisa con su id',
      setUp: () =>
          when(() => copy('n1')).thenAnswer((_) async => const Success(_copy)),
      build: () => SharedNoteDetailBloc(getNote: getNote, copyNote: copy),
      act: (bloc) async {
        bloc.add(const SharedNoteDetailEvent.started('n1'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const SharedNoteDetailEvent.copyRequested());
      },
      expect: () => const [
        SharedNoteDetailState(noteId: 'n1'),
        SharedNoteDetailState(noteId: 'n1', loading: false, note: _note),
        SharedNoteDetailState(
          noteId: 'n1',
          loading: false,
          note: _note,
          copying: true,
        ),
        SharedNoteDetailState(
          noteId: 'n1',
          loading: false,
          note: _note,
          copiedNoteId: 'c1',
        ),
      ],
    );

    blocTest<SharedNoteDetailBloc, SharedNoteDetailState>(
      'un apunte que ya no se puede ver da error',
      setUp: () => when(() => getNote('n2')).thenAnswer(
        (_) async => const Failure(AppError.business('NOTE_NOT_FOUND')),
      ),
      build: () => SharedNoteDetailBloc(getNote: getNote, copyNote: copy),
      act: (bloc) => bloc.add(const SharedNoteDetailEvent.started('n2')),
      expect: () => const [
        SharedNoteDetailState(noteId: 'n2'),
        SharedNoteDetailState(
          noteId: 'n2',
          loading: false,
          error: AppError.business('NOTE_NOT_FOUND'),
        ),
      ],
    );
  });
}
