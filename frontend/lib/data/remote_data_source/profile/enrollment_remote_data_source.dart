import 'package:dio/dio.dart';

import '../../../domain/models/academic/subject_file.dart';
import '../api/api_client.dart';
import '../../../domain/models/profile/enrollment_proposal.dart';

/// Endpoints de importación de la matrícula (`/api/v1/profile/enrollment`).
/// Las respuestas son pequeñas y planas: se convierten aquí mismo.
class EnrollmentRemoteDataSource {
  EnrollmentRemoteDataSource(ApiClient client) : _dio = client.dio;

  final Dio _dio;

  static const _base = '/api/v1/profile/enrollment';

  Future<EnrollmentProposal> read(
    FileUploadPayload file, {
    required bool consent,
  }) async {
    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        file.bytes,
        filename: file.fileName,
        contentType: DioMediaType.parse(file.mimeType),
      ),
    });
    final response = await _dio.post<Map<String, dynamic>>(
      '$_base/read',
      data: form,
      queryParameters: {'consent': consent},
      options: Options(contentType: Headers.multipartFormDataContentType),
    );
    final data = response.data ?? const <String, dynamic>{};
    return EnrollmentProposal(
      universityName: data['universityName'] as String?,
      universityId: data['universityId'] as String?,
      centerName: data['centerName'] as String?,
      degreeName: data['degreeName'] as String?,
      degreeId: data['degreeId'] as String?,
      academicYear: data['academicYear'] as String?,
      subjects: [
        for (final s in data['subjects'] as List<dynamic>? ?? const [])
          _subject(s as Map<String, dynamic>),
      ],
    );
  }

  Future<EnrollmentApplyResult> apply({
    String? degreeId,
    required List<String> catalogSubjectIds,
    required List<EnrollmentSubject> customSubjects,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_base/apply',
      data: {
        'degreeId': ?degreeId,
        'catalogSubjectIds': catalogSubjectIds,
        'customSubjects': [
          for (final s in customSubjects)
            {'name': s.name, 'code': ?s.code, 'credits': ?s.credits?.round()},
        ],
      },
    );
    final data = response.data ?? const <String, dynamic>{};
    return EnrollmentApplyResult(
      subjectsAdded: (data['subjectsAdded'] as num?)?.toInt() ?? 0,
      degreeLinked: data['degreeLinked'] as bool? ?? false,
    );
  }

  static EnrollmentSubject _subject(Map<String, dynamic> s) =>
      EnrollmentSubject(
        code: s['code'] as String?,
        name: s['name'] as String? ?? '',
        course: (s['course'] as num?)?.toInt(),
        credits: (s['credits'] as num?)?.toDouble(),
        period: s['period'] as String?,
        timesEnrolled: (s['timesEnrolled'] as num?)?.toInt(),
        catalogSubjectId: s['catalogSubjectId'] as String?,
        alreadyAdded: s['alreadyAdded'] as bool? ?? false,
      );
}
