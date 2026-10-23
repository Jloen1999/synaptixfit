import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/domain/enums/evaluation_mode.dart';
import 'package:synaptixfit/domain/enums/study_source_type.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/academic/study_document.dart';
import 'package:synaptixfit/domain/models/academic/subject_file.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/use_cases/academic/delete_note_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/delete_subject_file_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/get_document_availability_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/get_notes_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/get_study_materials_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/get_subject_files_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/get_subject_retention_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/get_subject_timeline_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/get_teaching_guide_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/register_study_material_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/set_assessment_grade_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/set_syllabus_topic_completed_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/set_teaching_guide_mode_use_case.dart';
import 'package:synaptixfit/domain/use_cases/academic/upload_subject_file_use_case.dart';
import 'package:synaptixfit/presentation/screens/academic/subject_detail/bloc/subject_progress_bloc.dart';
import 'package:synaptixfit/presentation/screens/academic/subject_detail/bloc/subject_syllabus_bloc.dart';

import 'academic_fixtures.dart';

class _GetGuide extends Mock implements GetTeachingGuideUseCaseContract {}

class _SetMode extends Mock implements SetTeachingGuideModeUseCaseContract {}

class _SetTopic extends Mock
    implements SetSyllabusTopicCompletedUseCaseContract {}

class _SetGrade extends Mock implements SetAssessmentGradeUseCaseContract {}

class _GetRetention extends Mock
    implements GetSubjectRetentionUseCaseContract {}

class _GetTimeline extends Mock implements GetSubjectTimelineUseCaseContract {}

class _GetMaterials extends Mock implements GetStudyMaterialsUseCaseContract {}

class _GetFiles extends Mock implements GetSubjectFilesUseCaseContract {}

class _GetNotes extends Mock implements GetNotesUseCaseContract {}

class _GetAvailability extends Mock
    implements GetDocumentAvailabilityUseCaseContract {}

class _Upload extends Mock implements UploadSubjectFileUseCaseContract {}

class _DeleteFile extends Mock implements DeleteSubjectFileUseCaseContract {}

class _DeleteNote extends Mock implements DeleteNoteUseCaseContract {}

class _Register extends Mock implements RegisterStudyMaterialUseCaseContract {}

void main() {
  setUpAll(() {
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(StudySourceType.note);
    registerFallbackValue(EvaluationMode.continuous);
    registerFallbackValue(
      FileUploadPayload(fileName: 'x', mimeType: 'x', bytes: Uint8List(0)),
    );
  });

  group('SubjectProgressBloc', () {
    late _GetGuide getGuide;
    late _SetMode setMode;
    late _SetTopic setTopic;
    late _SetGrade setGrade;
    late _GetRetention getRetention;
    late _GetTimeline getTimeline;
    late _GetMaterials getMaterials;

    setUp(() {
      getGuide = _GetGuide();
      setMode = _SetMode();
      setTopic = _SetTopic();
      setGrade = _SetGrade();
      getRetention = _GetRetention();
      getTimeline = _GetTimeline();
      getMaterials = _GetMaterials();
      when(
        () => getRetention('s1'),
      ).thenAnswer((_) async => const Success(retention));
      when(
        () => getTimeline(
          's1',
          from: any(named: 'from'),
          to: any(named: 'to'),
        ),
      ).thenAnswer((_) async => const Success([]));
      when(
        () => getMaterials(subjectId: 's1'),
      ).thenAnswer((_) async => const Success([material]));
    });

    SubjectProgressBloc build() => SubjectProgressBloc(
      getGuide: getGuide,
      setMode: setMode,
      setTopic: setTopic,
      setGrade: setGrade,
      getRetention: getRetention,
      getTimeline: getTimeline,
      getMaterials: getMaterials,
      clock: () => DateTime(2026, 10, 18, 12),
    );

    blocTest<SubjectProgressBloc, SubjectProgressState>(
      'sin guía: carga retención y materiales',
      setUp: () => when(
        () => getGuide('s1'),
      ).thenAnswer((_) async => const Success(null)),
      build: build,
      act: (bloc) => bloc.add(const SubjectProgressEvent.started('s1')),
      skip: 1,
      expect: () => const [
        SubjectProgressState(
          subjectId: 's1',
          loading: false,
          retention: retention,
          materials: [material],
        ),
      ],
    );

    blocTest<SubjectProgressBloc, SubjectProgressState>(
      'marcar un tema es optimista y se revierte si falla',
      setUp: () => when(
        () => setTopic('s1', 0, true),
      ).thenAnswer((_) async => const Failure(AppError.network())),
      build: build,
      seed: () => const SubjectProgressState(
        subjectId: 's1',
        loading: false,
        guide: guide,
      ),
      act: (bloc) => bloc.add(
        const SubjectProgressEvent.topicToggled(index: 0, completed: true),
      ),
      expect: () => [
        SubjectProgressState(
          subjectId: 's1',
          loading: false,
          guide: guide.copyWith(
            topics: [guide.topics.first.copyWith(completed: true)],
          ),
        ),
        const SubjectProgressState(
          subjectId: 's1',
          loading: false,
          guide: guide,
          actionError: AppError.network(),
        ),
      ],
    );

    blocTest<SubjectProgressBloc, SubjectProgressState>(
      'guarda la nota de un criterio con la estimación del servidor',
      setUp: () => when(
        () => setGrade('s1', 0, 8),
      ).thenAnswer((_) async => const Success(guide)),
      build: build,
      seed: () => const SubjectProgressState(subjectId: 's1', loading: false),
      act: (bloc) =>
          bloc.add(const SubjectProgressEvent.gradeChanged(index: 0, grade: 8)),
      expect: () => const [
        SubjectProgressState(
          subjectId: 's1',
          loading: false,
          savingGrade: true,
        ),
        SubjectProgressState(subjectId: 's1', loading: false, guide: guide),
      ],
    );

    blocTest<SubjectProgressBloc, SubjectProgressState>(
      'cambia la modalidad de evaluación y usa la guía recalculada',
      setUp: () => when(
        () => setMode('s1', EvaluationMode.global),
      ).thenAnswer((_) async => const Success(guide)),
      build: build,
      seed: () => const SubjectProgressState(subjectId: 's1', loading: false),
      act: (bloc) => bloc.add(
        const SubjectProgressEvent.modeChanged(EvaluationMode.global),
      ),
      expect: () => const [
        SubjectProgressState(
          subjectId: 's1',
          loading: false,
          savingGrade: true,
        ),
        SubjectProgressState(subjectId: 's1', loading: false, guide: guide),
      ],
    );

    blocTest<SubjectProgressBloc, SubjectProgressState>(
      'no llama al servidor si la modalidad ya es la activa',
      build: build,
      seed: () => SubjectProgressState(
        subjectId: 's1',
        loading: false,
        guide: guide.copyWith(effectiveMode: EvaluationMode.global),
      ),
      act: (bloc) => bloc.add(
        const SubjectProgressEvent.modeChanged(EvaluationMode.global),
      ),
      expect: () => const <SubjectProgressState>[],
      verify: (_) => verifyNever(() => setMode(any(), any())),
    );
  });

  group('SubjectSyllabusBloc', () {
    late _GetNotes getNotes;
    late _GetFiles getFiles;
    late _GetAvailability getAvailability;
    late _Upload upload;
    late _DeleteFile deleteFile;
    late _DeleteNote deleteNote;
    late _Register register;
    const available = DocumentAvailability(
      summary: true,
      mindMap: false,
      practice: false,
    );

    setUp(() {
      getNotes = _GetNotes();
      getFiles = _GetFiles();
      getAvailability = _GetAvailability();
      upload = _Upload();
      deleteFile = _DeleteFile();
      deleteNote = _DeleteNote();
      register = _Register();
      when(
        () => getNotes(subjectId: 's1'),
      ).thenAnswer((_) async => const Success([note]));
      when(() => getFiles('s1')).thenAnswer((_) async => const Success([file]));
      when(
        () => getAvailability(StudySourceType.note, 'n1'),
      ).thenAnswer((_) async => const Success(available));
      when(
        () => getAvailability(StudySourceType.file, 'f1'),
      ).thenAnswer((_) async => const Success(DocumentAvailability.none));
    });

    SubjectSyllabusBloc build() => SubjectSyllabusBloc(
      getNotes: getNotes,
      getFiles: getFiles,
      getAvailability: getAvailability,
      uploadFile: upload,
      deleteFile: deleteFile,
      deleteNote: deleteNote,
      registerMaterial: register,
    );

    blocTest<SubjectSyllabusBloc, SubjectSyllabusState>(
      'carga apuntes y archivos y luego los documentos de IA guardados',
      build: build,
      act: (bloc) => bloc.add(const SubjectSyllabusEvent.started('s1')),
      skip: 1,
      expect: () => const [
        SubjectSyllabusState(
          subjectId: 's1',
          loading: false,
          notes: [note],
          files: [file],
        ),
        SubjectSyllabusState(
          subjectId: 's1',
          loading: false,
          notes: [note],
          files: [file],
          availability: {'n1': available},
        ),
      ],
    );

    blocTest<SubjectSyllabusBloc, SubjectSyllabusState>(
      'sube un archivo informando del progreso',
      setUp: () =>
          when(
            () => upload('s1', any(), onProgress: any(named: 'onProgress')),
          ).thenAnswer((invocation) async {
            final onProgress =
                invocation.namedArguments[#onProgress] as void Function(double);
            onProgress(0.5);
            return const Success(file);
          }),
      build: build,
      seed: () => const SubjectSyllabusState(subjectId: 's1', loading: false),
      act: (bloc) => bloc.add(
        SubjectSyllabusEvent.uploadRequested(
          FileUploadPayload(
            fileName: 'guia.pdf',
            mimeType: 'application/pdf',
            bytes: Uint8List(3),
          ),
        ),
      ),
      expect: () => const [
        SubjectSyllabusState(
          subjectId: 's1',
          loading: false,
          uploadProgress: 0,
        ),
        SubjectSyllabusState(
          subjectId: 's1',
          loading: false,
          uploadProgress: 0.5,
        ),
        SubjectSyllabusState(
          subjectId: 's1',
          loading: false,
          files: [file],
          message: SyllabusMessage.fileUploaded,
        ),
      ],
    );

    blocTest<SubjectSyllabusBloc, SubjectSyllabusState>(
      'registra el material y pide abrir la práctica',
      setUp: () => when(
        () => register(StudySourceType.note, 'n1'),
      ).thenAnswer((_) async => const Success(material)),
      build: build,
      seed: () => const SubjectSyllabusState(subjectId: 's1', loading: false),
      act: (bloc) => bloc.add(
        const SubjectSyllabusEvent.materialRequested(
          sourceType: StudySourceType.note,
          sourceId: 'n1',
          practice: true,
        ),
      ),
      expect: () => const [
        SubjectSyllabusState(subjectId: 's1', loading: false, busy: true),
        SubjectSyllabusState(
          subjectId: 's1',
          loading: false,
          navigation: (materialId: 'm1', practice: true),
        ),
      ],
    );

    blocTest<SubjectSyllabusBloc, SubjectSyllabusState>(
      'borrar un apunte lo quita de la lista',
      setUp: () => when(
        () => deleteNote('n1'),
      ).thenAnswer((_) async => const Success(unit)),
      build: build,
      seed: () => const SubjectSyllabusState(
        subjectId: 's1',
        loading: false,
        notes: [note],
      ),
      act: (bloc) => bloc.add(const SubjectSyllabusEvent.noteDeleted('n1')),
      expect: () => const [
        SubjectSyllabusState(
          subjectId: 's1',
          loading: false,
          message: SyllabusMessage.noteDeleted,
        ),
      ],
    );
  });
}
