import 'package:dio/dio.dart';

import '../../../domain/models/training/training_page.dart';
import '../api/api_client.dart';
import 'dto/page_dto.dart';
import 'dto/proposal_dto.dart';
import 'dto/routine_dto.dart';

/// Rutinas (`/api/v1/routines`). Casi todas las ediciones devuelven la rutina completa.
class RoutineRemoteDataSource {
  RoutineRemoteDataSource(ApiClient client) : _dio = client.dio;

  final Dio _dio;

  static const _base = '/api/v1/routines';

  Future<TrainingPage<RoutineSummaryDto>> listMine({
    String? status,
    required int page,
    required int size,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      _base,
      queryParameters: {'status': ?status, 'page': page, 'size': size},
    );
    return parseTrainingPage(response.data!, RoutineSummaryDto.fromJson);
  }

  Future<TrainingPage<RoutineSummaryDto>> community({
    String? query,
    String? goal,
    required int page,
    required int size,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_base/community',
      queryParameters: {'q': ?query, 'goal': ?goal, 'page': page, 'size': size},
    );
    return parseTrainingPage(response.data!, RoutineSummaryDto.fromJson);
  }

  Future<RoutineDto> get(String routineId) =>
      _routine(_dio.get<Map<String, dynamic>>('$_base/$routineId'));

  Future<RoutineDto> create(CreateRoutineRequestDto request) =>
      _routine(_dio.post<Map<String, dynamic>>(_base, data: request.toJson()));

  Future<RoutineDto> update(String routineId, Map<String, dynamic> changes) =>
      _routine(
        _dio.patch<Map<String, dynamic>>('$_base/$routineId', data: changes),
      );

  Future<RoutineDto> changeStatus(String routineId, String status) => _routine(
    _dio.put<Map<String, dynamic>>(
      '$_base/$routineId/status',
      data: {'status': status},
    ),
  );

  Future<RoutineDto> skipDay(String routineId, String dayId) => _routine(
    _dio.post<Map<String, dynamic>>('$_base/$routineId/days/$dayId/skip'),
  );

  Future<RoutineDto> unskipDay(String routineId, String dayId) => _routine(
    _dio.post<Map<String, dynamic>>('$_base/$routineId/days/$dayId/unskip'),
  );

  Future<RoutineDto> restart(String routineId) => _routine(
    _dio.post<Map<String, dynamic>>('$_base/$routineId/restart'),
  );

  Future<void> delete(String routineId) =>
      _dio.delete<void>('$_base/$routineId');

  Future<RoutineDto> duplicate(String routineId, String? name) => _routine(
    _dio.post<Map<String, dynamic>>(
      '$_base/$routineId/duplicate',
      data: {'name': ?name},
    ),
  );

  Future<RoutineDto> clone(String routineId) =>
      _routine(_dio.post<Map<String, dynamic>>('$_base/$routineId/clone'));

  Future<RoutineDto> addWeek(String routineId, String? name, String? type) =>
      _routine(
        _dio.post<Map<String, dynamic>>(
          '$_base/$routineId/weeks',
          data: {'name': ?name, 'type': ?type},
        ),
      );

  Future<RoutineDto> updateWeek(
    String routineId,
    String weekId,
    String? name,
    String? type,
  ) => _routine(
    _dio.patch<Map<String, dynamic>>(
      '$_base/$routineId/weeks/$weekId',
      data: {'name': ?name, 'type': ?type},
    ),
  );

  Future<RoutineDto> deleteWeek(String routineId, String weekId) => _routine(
    _dio.delete<Map<String, dynamic>>('$_base/$routineId/weeks/$weekId'),
  );

  Future<RoutineDto> addDay(
    String routineId,
    String weekId,
    int dayNumber,
    String? name,
  ) => _routine(
    _dio.post<Map<String, dynamic>>(
      '$_base/$routineId/weeks/$weekId/days',
      data: {'dayNumber': dayNumber, 'name': ?name},
    ),
  );

  Future<RoutineDto> renameDay(String routineId, String dayId, String name) =>
      _routine(
        _dio.patch<Map<String, dynamic>>(
          '$_base/$routineId/days/$dayId',
          data: {'name': name},
        ),
      );

  Future<RoutineDto> deleteDay(String routineId, String dayId) => _routine(
    _dio.delete<Map<String, dynamic>>('$_base/$routineId/days/$dayId'),
  );

  Future<RoutineDto> addExercise(
    String routineId,
    String dayId,
    ProposedExerciseDto exercise,
  ) => _routine(
    _dio.post<Map<String, dynamic>>(
      '$_base/$routineId/days/$dayId/exercises',
      data: exercise.toJson()..remove('exerciseName'),
    ),
  );

  Future<RoutineDto> reorder(
    String routineId,
    String dayId,
    List<String> plannedExerciseIds,
  ) => _routine(
    _dio.put<Map<String, dynamic>>(
      '$_base/$routineId/days/$dayId/exercises/order',
      data: {'plannedExerciseIds': plannedExerciseIds},
    ),
  );

  Future<RoutineDto> updateExercise(
    String routineId,
    String plannedExerciseId,
    Map<String, dynamic> parameters,
  ) => _routine(
    _dio.put<Map<String, dynamic>>(
      '$_base/$routineId/exercises/$plannedExerciseId',
      data: parameters,
    ),
  );

  Future<RoutineDto> replaceExercise(
    String routineId,
    String plannedExerciseId,
    String exerciseId,
  ) => _routine(
    _dio.put<Map<String, dynamic>>(
      '$_base/$routineId/exercises/$plannedExerciseId/exercise',
      data: {'exerciseId': exerciseId},
    ),
  );

  Future<RoutineDto> removeExercise(
    String routineId,
    String plannedExerciseId,
  ) => _routine(
    _dio.delete<Map<String, dynamic>>(
      '$_base/$routineId/exercises/$plannedExerciseId',
    ),
  );

  Future<RoutineProposalDto> generate({
    required int durationWeeks,
    String? goal,
    required bool useAi,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_base/generate',
      data: {'durationWeeks': durationWeeks, 'goal': ?goal, 'useAi': useAi},
    );
    return RoutineProposalDto.fromJson(response.data!);
  }

  Future<RoutineProposalDto> refine(RoutineProposalDto proposal) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_base/refine',
      data: proposal.toJson(),
    );
    return RoutineProposalDto.fromJson(response.data!);
  }

  Future<RoutineDto> _routine(
    Future<Response<Map<String, dynamic>>> request,
  ) async => RoutineDto.fromJson((await request).data!);
}
