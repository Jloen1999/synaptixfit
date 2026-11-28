import 'package:dio/dio.dart';

import '../../../domain/models/training/wod.dart';
import '../api/api_client.dart';
import 'dto/wod_dtos.dart';

/// Llamadas de los WOD (`/training/wods`), ADR 0069.
class WodRemoteDataSource {
  WodRemoteDataSource(ApiClient client) : _dio = client.dio;

  final Dio _dio;

  static const _wods = '/api/v1/training/wods';

  Future<List<Wod>> listTemplates() async {
    final r = await _dio.get<List<dynamic>>('$_wods/templates');
    return [
      for (final t in r.data ?? const [])
        WodDtos.wod(t as Map<String, dynamic>),
    ];
  }

  Future<WodBoard> board({String? templateCode}) async {
    final r = await _dio.get<Map<String, dynamic>>(
      '$_wods/today',
      queryParameters: {'templateCode': ?templateCode},
    );
    return WodDtos.board(r.data!);
  }

  Future<Wod> create(Wod wod) async {
    final r = await _dio.post<Map<String, dynamic>>(
      _wods,
      data: WodDtos.wodBody(wod),
    );
    return WodDtos.wod(r.data!);
  }

  Future<Wod> update(Wod wod) async {
    final r = await _dio.put<Map<String, dynamic>>(
      '$_wods/${wod.id}',
      data: WodDtos.wodBody(wod),
    );
    return WodDtos.wod(r.data!);
  }

  Future<void> delete(String wodId) => _dio.delete<void>('$_wods/$wodId');

  Future<WodMark> saveResult(Wod wod, WodResultDraft draft) async {
    final r = await _dio.post<Map<String, dynamic>>(
      '$_wods/results',
      data: WodDtos.resultBody(wod, draft),
    );
    return WodDtos.mark(r.data!);
  }

  Future<List<WodMark>> listMarks() async {
    final r = await _dio.get<List<dynamic>>('$_wods/results');
    return [
      for (final m in r.data ?? const [])
        WodDtos.mark(m as Map<String, dynamic>),
    ];
  }
}
