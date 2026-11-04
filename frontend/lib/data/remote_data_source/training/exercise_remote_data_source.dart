import 'package:dio/dio.dart';

import '../../../domain/models/training/exercise.dart';
import '../../../domain/models/training/exercise_guide.dart';
import '../../../domain/models/training/training_page.dart';
import '../api/api_client.dart';
import 'dto/exercise_dto.dart';
import 'dto/page_dto.dart';

/// Catálogo de ejercicios (`/api/v1/exercises`).
class ExerciseRemoteDataSource {
  ExerciseRemoteDataSource(ApiClient client) : _dio = client.dio;

  final Dio _dio;

  static const _base = '/api/v1/exercises';

  Future<TrainingPage<ExerciseDto>> search(
    ExerciseSearchCriteria c, {
    required int page,
    required int size,
  }) async {
    final query = c.query?.trim();
    final response = await _dio.get<Map<String, dynamic>>(
      _base,
      queryParameters: {
        if (query != null && query.isNotEmpty) 'q': query,
        'bodyPartId': ?c.bodyPartId,
        'muscleId': ?c.muscleId,
        'equipmentId': ?c.equipmentId,
        'difficulty': ?c.difficulty?.apiValue,
        'modality': ?c.modality?.apiValue,
        'purpose': ?c.purpose?.apiValue,
        'category': ?c.category?.apiValue,
        'page': page,
        'size': size,
      },
    );
    return parseTrainingPage(response.data!, ExerciseDto.fromJson);
  }

  Future<ExerciseDto> get(String exerciseId) async {
    final response = await _dio.get<Map<String, dynamic>>('$_base/$exerciseId');
    return ExerciseDto.fromJson(response.data!);
  }

  /// Ejercicios que pueden sustituir a este (mismo músculo principal).
  Future<List<ExerciseDto>> alternatives(String exerciseId) async {
    final response = await _dio.get<List<dynamic>>(
      '$_base/$exerciseId/alternatives',
    );
    return (response.data ?? const [])
        .cast<Map<String, dynamic>>()
        .map(ExerciseDto.fromJson)
        .toList();
  }

  /// Calentamiento y vuelta a la calma para los ejercicios de una sesión.
  Future<({List<ExerciseDto> warmUp, List<ExerciseDto> coolDown})> bookends(
    List<String> exerciseIds,
  ) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_base/bookends',
      queryParameters: {'exerciseIds': exerciseIds.join(',')},
    );
    List<ExerciseDto> list(String key) =>
        ((response.data?[key] as List<dynamic>?) ?? const [])
            .cast<Map<String, dynamic>>()
            .map(ExerciseDto.fromJson)
            .toList();
    return (warmUp: list('warmUp'), coolDown: list('coolDown'));
  }

  Future<ExerciseFilterOptionsDto> filters() async {
    final response = await _dio.get<Map<String, dynamic>>('$_base/filters');
    return ExerciseFilterOptionsDto.fromJson(response.data!);
  }

  /// «Las claves» y «Errores comunes» en el idioma de la app (ADR 0031).
  Future<ExerciseTips> tips(String exerciseId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_base/$exerciseId/tips',
    );
    List<String> lines(String key) =>
        ((response.data?[key] as List<dynamic>?) ?? const []).cast<String>();
    return ExerciseTips(
      keyPoints: lines('keyPoints'),
      commonMistakes: lines('commonMistakes'),
    );
  }

  Future<ExerciseNote?> note(String exerciseId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_base/$exerciseId/note',
    );
    return _note(response.data);
  }

  Future<ExerciseNote?> saveNote(String exerciseId, String text) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '$_base/$exerciseId/note',
      data: {'text': text},
    );
    return _note(response.data);
  }

  static ExerciseNote? _note(Map<String, dynamic>? json) {
    final text = json?['text'] as String?;
    final at = json?['updatedAt'] as String?;
    if (text == null || at == null) return null;
    return ExerciseNote(text: text, updatedAt: DateTime.parse(at).toLocal());
  }
}
