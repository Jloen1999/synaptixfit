import 'package:dio/dio.dart';

import '../../../domain/models/training/run.dart';
import '../api/api_client.dart';
import 'dto/run_dtos.dart';

/// Llamadas de las carreras con GPS (`/training/runs`) y de los entrenos de
/// carrera (`/training/run-workouts`), ADR 0037.
class RunRemoteDataSource {
  RunRemoteDataSource(ApiClient client) : _dio = client.dio;

  final Dio _dio;

  static const _runs = '/api/v1/training/runs';
  static const _workouts = '/api/v1/training/run-workouts';

  Future<RunSaved> upload(RunRecording recording) async {
    final r = await _dio.post<Map<String, dynamic>>(
      _runs,
      data: RunDtos.recordingBody(recording),
    );
    return RunDtos.saved(r.data!);
  }

  Future<RunDetail> getRun(String blockId) async {
    final r = await _dio.get<Map<String, dynamic>>('$_runs/$blockId');
    return RunDtos.detail(r.data!);
  }

  Future<void> deleteRun(String blockId) =>
      _dio.delete<void>('$_runs/$blockId');

  Future<RunWeek> getWeek() async {
    final r = await _dio.get<Map<String, dynamic>>('$_runs/week');
    return RunDtos.week(r.data!);
  }

  Future<List<RunWorkout>> listWorkouts() async {
    final r = await _dio.get<List<dynamic>>(_workouts);
    return [
      for (final w in r.data ?? const [])
        RunDtos.workout(w as Map<String, dynamic>),
    ];
  }

  Future<List<RunWorkout>> listTemplates() async {
    final r = await _dio.get<List<dynamic>>('$_workouts/templates');
    return [
      for (final t in r.data ?? const [])
        RunDtos.template(t as Map<String, dynamic>),
    ];
  }

  Future<RunWorkout> createWorkout(RunWorkout w) async {
    final r = await _dio.post<Map<String, dynamic>>(
      _workouts,
      data: RunDtos.workoutBody(w),
    );
    return RunDtos.workout(r.data!);
  }

  Future<RunWorkout> updateWorkout(RunWorkout w) async {
    final r = await _dio.put<Map<String, dynamic>>(
      '$_workouts/${w.id}',
      data: RunDtos.workoutBody(w),
    );
    return RunDtos.workout(r.data!);
  }

  Future<void> deleteWorkout(String id) => _dio.delete<void>('$_workouts/$id');

  Future<String> scheduleWorkout(String id, DateTime start) async {
    final r = await _dio.post<Map<String, dynamic>>(
      '$_workouts/$id/schedule',
      data: {'start': start.toUtc().toIso8601String()},
    );
    return r.data!['blockId'] as String;
  }

  Future<List<PlannedRun>> listPlanned() async {
    final r = await _dio.get<List<dynamic>>('$_workouts/planned');
    return [
      for (final p in r.data ?? const [])
        RunDtos.planned(p as Map<String, dynamic>),
    ];
  }
}
