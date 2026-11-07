import 'package:dio/dio.dart';

import '../api/api_client.dart';
import 'dto/note_dtos.dart';

/// Endpoints de apuntes (`/api/v1/notes`).
class NotesRemoteDataSource {
  NotesRemoteDataSource(ApiClient client) : _dio = client.dio;

  final Dio _dio;

  static const _base = '/api/v1/notes';

  /// Tamaño de página al listar todos los apuntes de una asignatura.
  static const _pageSize = 100;

  /// [unassignedOnly]: solo los que no tienen asignatura (bandeja de notas).
  Future<NotePageDto> getNotes({
    String? subjectId,
    int page = 0,
    bool unassignedOnly = false,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      _base,
      queryParameters: {
        'subjectId': ?subjectId,
        if (unassignedOnly) 'unassignedOnly': true,
        'page': page,
        'size': _pageSize,
      },
    );
    return NotePageDto.fromJson(response.data!);
  }

  Future<NoteDto> getNote(String id) async {
    final response = await _dio.get<Map<String, dynamic>>('$_base/$id');
    return NoteDto.fromJson(response.data!);
  }

  Future<NoteDto> createNote(Map<String, dynamic> body) async {
    final response = await _dio.post<Map<String, dynamic>>(_base, data: body);
    return NoteDto.fromJson(response.data!);
  }

  Future<NoteDto> updateNote(String id, Map<String, dynamic> body) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '$_base/$id',
      data: body,
    );
    return NoteDto.fromJson(response.data!);
  }

  Future<void> deleteNote(String id) => _dio.delete<void>('$_base/$id');

  Future<SharedNotePageDto> getSharedNotes({
    required int page,
    required int size,
    required String scope,
    String? authorId,
    String? search,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_base/shared',
      queryParameters: {
        'page': page,
        'size': size,
        'scope': scope,
        'authorId': ?authorId,
        'q': ?search,
      },
    );
    return SharedNotePageDto.fromJson(response.data!);
  }

  Future<SharedNoteDto> getSharedNote(String id) async {
    final response = await _dio.get<Map<String, dynamic>>('$_base/shared/$id');
    return SharedNoteDto.fromJson(response.data!);
  }

  /// Copia privada en mis apuntes (`POST /notes/shared/{id}/copy`).
  Future<NoteDto> copySharedNote(String id) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_base/shared/$id/copy',
    );
    return NoteDto.fromJson(response.data!);
  }

  /// Envía las fotos (campo `files`, varias) y recibe el borrador leído.
  /// Leer y ordenar varias páginas tarda: se da más margen que al resto.
  Future<ScannedNoteDraftDto> readNotePhotos(
    List<({List<int> bytes, String fileName, String mimeType})> photos,
  ) async {
    final form = FormData();
    for (final photo in photos) {
      form.files.add(
        MapEntry(
          'files',
          MultipartFile.fromBytes(
            photo.bytes,
            filename: photo.fileName,
            contentType: DioMediaType.parse(photo.mimeType),
          ),
        ),
      );
    }
    final response = await _dio.post<Map<String, dynamic>>(
      '$_base/scan-drafts',
      data: form,
      options: Options(
        contentType: Headers.multipartFormDataContentType,
        receiveTimeout: const Duration(minutes: 3),
      ),
    );
    return ScannedNoteDraftDto.fromJson(response.data!);
  }
}
