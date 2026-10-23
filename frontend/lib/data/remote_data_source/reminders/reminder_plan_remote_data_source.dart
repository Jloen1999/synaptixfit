import 'package:dio/dio.dart';

import '../api/api_client.dart';
import 'dto/reminder_plan_dto.dart';

/// Plan de recordatorios del móvil (`/api/v1/notifications/reminder-plan`).
class ReminderPlanRemoteDataSource {
  ReminderPlanRemoteDataSource(ApiClient client) : _dio = client.dio;

  final Dio _dio;

  static const _path = '/api/v1/notifications/reminder-plan';

  Future<ReminderPlanDto> get({required int days}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      _path,
      queryParameters: {'days': days},
    );
    return ReminderPlanDto.fromJson(response.data!);
  }
}
