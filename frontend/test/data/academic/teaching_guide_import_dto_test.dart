import 'package:flutter_test/flutter_test.dart';
import 'package:synaptixfit/data/remote_data_source/academic/dto/subject_dtos.dart';
import 'package:synaptixfit/data/remote_data_source/academic/dto/teaching_guide_import_dtos.dart';
import 'package:synaptixfit/domain/enums/assessment_kind.dart';
import 'package:synaptixfit/domain/enums/evaluation_mode.dart';
import 'package:synaptixfit/domain/enums/teaching_guide_import_status.dart';

void main() {
  final json = {
    'id': 'i1',
    'status': 'READY',
    'fileName': 'plan.pdf',
    'suggestedSubjectId': 's1',
    'suggestedSubjectName': 'Hardware',
    'guide': {
      'subject': {'name': 'Hardware', 'code': '502376', 'ectsCredits': 4.5},
      'topics': [
        {
          'title': 'Tema 1',
          'kind': 'THEORY',
          'subtopics': ['SoC'],
          'hours': 27,
        },
      ],
      'assessments': [
        {
          'name': 'Prueba 1',
          'percentage': 30,
          'mode': 'CONTINUOUS',
          'kind': 'EXAM',
          'topicNumbers': [1],
          'recoverable': false,
          'dueDate': '2026-11-20',
        },
        {'name': 'Global', 'percentage': 100, 'mode': 'GLOBAL', 'kind': 'EXAM'},
      ],
      'selectedMode': null,
    },
  };

  test('TeachingGuideImportDto mapea estado, sugerencia y borrador', () {
    final i = TeachingGuideImportDto.fromJson(json).toDomain();

    expect(i.status, TeachingGuideImportStatus.ready);
    expect(i.suggestedSubjectName, 'Hardware');
    final draft = i.draft!;
    expect(draft.info.ectsCredits, 4.5);
    expect(draft.topics.single.subtopics, ['SoC']);
    expect(draft.assessments.first.kind, AssessmentKind.exam);
    expect(draft.assessments.first.dueDate, DateTime(2026, 11, 20));
    expect(draft.modes, [EvaluationMode.continuous, EvaluationMode.global]);
    expect(draft.effectiveMode, EvaluationMode.continuous);
    expect(draft.activeAssessments.map((e) => e.$1), [0]);
  });

  test('el borrador editado vuelve con días ISO y modalidad elegida', () {
    final draft = TeachingGuideImportDto.fromJson(json).toDomain().draft!;
    final edited = draft.copyWith(selectedMode: EvaluationMode.global);

    final body = GuideDraftDto.fromDomain(edited).toJson();

    expect(body['selectedMode'], 'GLOBAL');
    final first = (body['assessments'] as List).first;
    expect((first as AssessmentDraftDto).dueDate, '2026-11-20');
    expect(edited.activeAssessments.map((e) => e.$2.name), ['Global']);
    expect(edited.activeTotal, 100);
  });

  test('TeachingGuideDto lee datos de la asignatura y criterios activos', () {
    final guide = TeachingGuideDto.fromJson({
      'subjectId': 's1',
      'subject': {'ectsCredits': 6, 'semester': 6},
      'assessments': [
        {
          'index': 0,
          'name': 'Global',
          'percentage': 100,
          'mode': 'GLOBAL',
          'active': false,
        },
      ],
      'availableModes': ['CONTINUOUS', 'GLOBAL'],
      'effectiveMode': 'CONTINUOUS',
      'syllabusProgress': 0,
    }).toDomain();

    expect(guide.info.semester, 6);
    expect(guide.availableModes, hasLength(2));
    expect(guide.effectiveMode, EvaluationMode.continuous);
    expect(guide.assessments.single.active, isFalse);
  });
}
