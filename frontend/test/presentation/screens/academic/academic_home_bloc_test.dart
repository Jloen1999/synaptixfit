import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/domain/enums/data_topic.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/use_cases/academic/get_due_study_materials_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/get_subjects_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/get_unassigned_notes_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/move_note_to_subject_use_case.dart';
import 'package:synaptixfit/domain/models/academic/subject.dart';
import 'package:synaptixfit/presentation/screens/academic/academic_home/bloc/academic_home_bloc.dart';

import '../data_changes_fake.dart';
import 'academic_fixtures.dart';

class _GetSubjects extends Mock implements GetSubjectsUseCaseContract {}

class _GetDue extends Mock implements GetDueStudyMaterialsUseCaseContract {}

class _GetInbox extends Mock implements GetUnassignedNotesUseCaseContract {}

class _MoveNote extends Mock implements MoveNoteToSubjectUseCaseContract {}

void main() {
  group('AcademicHomeBloc', () {
    late _GetSubjects getSubjects;
    late _GetDue getDue;
    late _GetInbox getInbox;
    late _MoveNote moveNote;
    late FakeDataChanges changes;

    setUp(() {
      getSubjects = _GetSubjects();
      getDue = _GetDue();
      getInbox = _GetInbox();
      moveNote = _MoveNote();
      when(() => getInbox()).thenAnswer((_) async => const Success([]));
      changes = FakeDataChanges();
      when(
        () => getSubjects(archived: false),
      ).thenAnswer((_) async => const Success([subject]));
      when(() => getDue()).thenAnswer((_) async => const Success([material]));
    });

    tearDown(() => changes.close());

    AcademicHomeBloc build() => AcademicHomeBloc(
      getSubjects: getSubjects,
      getDue: getDue,
      getInbox: getInbox,
      moveNote: moveNote,
      watchChanges: changes.useCase,
    );

    blocTest<AcademicHomeBloc, AcademicHomeState>(
      'carga asignaturas y repasos pendientes',
      setUp: () => when(
        () => getSubjects(archived: false),
      ).thenAnswer((_) async => const Success([subject])),
      build: build,
      act: (bloc) => bloc.add(const AcademicHomeEvent.started()),
      expect: () => const [
        AcademicHomeState(),
        AcademicHomeState(loading: false, subjects: [subject], due: [material]),
      ],
    );

    blocTest<AcademicHomeBloc, AcademicHomeState>(
      'emite el error si fallan las asignaturas',
      setUp: () => when(
        () => getSubjects(archived: false),
      ).thenAnswer((_) async => const Failure(AppError.network())),
      build: build,
      act: (bloc) => bloc.add(const AcademicHomeEvent.started()),
      expect: () => const [
        AcademicHomeState(),
        AcademicHomeState(loading: false, error: AppError.network()),
      ],
    );

    blocTest<AcademicHomeBloc, AcademicHomeState>(
      'el filtro pide las archivadas',
      setUp: () => when(
        () => getSubjects(archived: true),
      ).thenAnswer((_) async => const Success(<Subject>[])),
      build: build,
      act: (bloc) =>
          bloc.add(const AcademicHomeEvent.archivedToggled(archived: true)),
      verify: (_) => verify(() => getSubjects(archived: true)).called(1),
      skip: 1,
      expect: () => const [
        AcademicHomeState(loading: false, showArchived: true, due: [material]),
      ],
    );

    blocTest<AcademicHomeBloc, AcademicHomeState>(
      'un cambio del planificador la refresca en silencio',
      build: build,
      act: (bloc) async {
        bloc.add(const AcademicHomeEvent.started());
        await pump();
        changes.emit({DataTopic.planner});
        await pump();
      },
      verify: (_) => verify(() => getSubjects(archived: false)).called(2),
    );

    blocTest<AcademicHomeBloc, AcademicHomeState>(
      'un cambio de entrenamiento no la refresca',
      build: build,
      act: (bloc) async {
        bloc.add(const AcademicHomeEvent.started());
        await pump();
        changes.emit({DataTopic.training});
        await pump();
      },
      verify: (_) => verify(() => getSubjects(archived: false)).called(1),
    );

    blocTest<AcademicHomeBloc, AcademicHomeState>(
      'carga la bandeja de notas sin asignatura',
      setUp: () =>
          when(() => getInbox()).thenAnswer((_) async => const Success([note])),
      build: build,
      act: (bloc) => bloc.add(const AcademicHomeEvent.started()),
      skip: 1,
      expect: () => const [
        AcademicHomeState(
          loading: false,
          subjects: [subject],
          due: [material],
          inbox: [note],
        ),
      ],
    );

    blocTest<AcademicHomeBloc, AcademicHomeState>(
      '«Mover a asignatura» la quita de la bandeja y avisa',
      setUp: () => when(
        () => moveNote(note.id, subjectId: subject.id),
      ).thenAnswer((_) async => const Success(note)),
      build: build,
      seed: () => const AcademicHomeState(
        loading: false,
        subjects: [subject],
        inbox: [note],
      ),
      act: (bloc) => bloc.add(
        AcademicHomeEvent.noteMoved(noteId: note.id, subjectId: subject.id),
      ),
      expect: () => [
        AcademicHomeState(
          loading: false,
          subjects: const [subject],
          inbox: const [note],
          movingNoteIds: {note.id},
        ),
        AcademicHomeState(
          loading: false,
          subjects: const [subject],
          notice: AcademicHomeNotice.noteMoved(subject.name, subject.id),
        ),
      ],
    );
  });
}
