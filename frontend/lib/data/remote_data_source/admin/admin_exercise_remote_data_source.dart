import 'package:dio/dio.dart';

import '../../../domain/models/admin/admin_page.dart';
import '../api/api_client.dart';
import 'dto/admin_exercise_dto.dart';
import 'dto/admin_json.dart';

/// Catálogo de ejercicios del panel (`/api/v1/admin/exercises/**`) y opciones
/// de los selectores (`/api/v1/exercises/filters`).
class AdminExerciseRemoteDataSource {
  AdminExerciseRemoteDataSource(ApiClient client) : _dio = client.dio;

  final Dio _dio;

  static const _base = '/api/v1/admin/exercises';

  Future<AdminPage<AdminExerciseDto>> search(Map<String, dynamic> query) async {
    final response = await _dio.get<Map<String, dynamic>>(
      _base,
      queryParameters: query,
    );
    return AdminJson.page(response.data!, AdminExerciseDto.fromJson);
  }

  Future<AdminExerciseDto> get(String exerciseId) async {
    final response = await _dio.get<Map<String, dynamic>>('$_base/$exerciseId');
    return AdminExerciseDto.fromJson(response.data!);
  }

  Future<AdminExerciseDto> create(Map<String, dynamic> body) async {
    final response = await _dio.post<Map<String, dynamic>>(_base, data: body);
    return AdminExerciseDto.fromJson(response.data!);
  }

  Future<AdminExerciseDto> update(
    String exerciseId,
    Map<String, dynamic> body,
  ) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '$_base/$exerciseId',
      data: body,
    );
    return AdminExerciseDto.fromJson(response.data!);
  }

  Future<AdminExerciseDto> setActive(String exerciseId, bool active) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '$_base/$exerciseId/active',
      data: {'active': active},
    );
    return AdminExerciseDto.fromJson(response.data!);
  }

  Future<AdminExerciseDeletionDto> delete(String exerciseId) async {
    final response = await _dio.delete<Map<String, dynamic>>(
      '$_base/$exerciseId',
    );
    return AdminExerciseDeletionDto.fromJson(response.data!);
  }

  Future<AdminExerciseOptionsDto> options() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/exercises/filters',
    );
    return AdminExerciseOptionsDto.fromJson(response.data!);
  }
}
