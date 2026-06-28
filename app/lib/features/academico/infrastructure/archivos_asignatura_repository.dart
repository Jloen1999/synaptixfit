import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env_config.dart';
import '../domain/archivo_asignatura_dto.dart';

/// Excepción de dominio para errores de subida/borrado de archivos.
class ArchivoStorageException implements Exception {
  ArchivoStorageException(this.mensaje);
  final String mensaje;
  @override
  String toString() => mensaje;
}

/// Repositorio que orquesta el almacenamiento estructurado de archivos:
///
/// - El binario físico se sube a **Cloudflare R2** mediante el Worker proxy
///   (`VITE_R2_WORKER_URL`) con un `PUT` HTTP directo a la clave de objeto.
/// - Los **metadatos** se persisten en Supabase (`archivos_asignatura`).
///
/// Jerarquía estricta de claves (evita colisiones):
///   `usuarios/{user_id}/asignaturas/{asignatura_id}/archivos/{ts}_{nombre.ext}`
class ArchivosAsignaturaRepository {
  ArchivosAsignaturaRepository({Dio? dio, SupabaseClient? client})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 20),
              sendTimeout: const Duration(minutes: 5),
              receiveTimeout: const Duration(seconds: 30),
            )),
        _client = client ?? Supabase.instance.client;

  final Dio _dio;
  final SupabaseClient _client;

  /// Lista los archivos de una asignatura (más recientes primero).
  Future<List<ArchivoAsignaturaDto>> listar(String asignaturaId) async {
    final user = _client.auth.currentUser;
    if (user == null) return [];
    final data = await _client
        .from('archivos_asignatura')
        .select()
        .eq('usuario_id', user.id)
        .eq('asignatura_id', asignaturaId)
        .order('creado_en', ascending: false);
    return (data as List)
        .map((e) => ArchivoAsignaturaDto.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// Sube un archivo a R2 y registra sus metadatos en Supabase.
  ///
  /// [onProgreso] reporta el progreso de subida (0.0 → 1.0).
  Future<ArchivoAsignaturaDto> subirArchivo({
    required String asignaturaId,
    required String nombreArchivo,
    required Uint8List bytes,
    String? mimeType,
    void Function(double progreso)? onProgreso,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw ArchivoStorageException('Sesión no válida.');
    }
    if (!EnvConfig.hasR2Worker) {
      throw ArchivoStorageException(
        'Almacenamiento no configurado (falta VITE_R2_WORKER_URL).',
      );
    }

    final nombreLimpio = _sanitizar(nombreArchivo);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final objectKey =
        'usuarios/${user.id}/asignaturas/$asignaturaId/archivos/${timestamp}_$nombreLimpio';
    final mime = mimeType ?? _inferirMime(nombreLimpio);

    // 1. PUT del binario a Cloudflare R2 (vía Worker proxy).
    final workerBase = EnvConfig.r2WorkerUrl.replaceAll(RegExp(r'/+$'), '');
    final uploadUrl = '$workerBase/$objectKey';
    try {
      await _dio.put<dynamic>(
        uploadUrl,
        data: bytes,
        options: Options(contentType: mime),
        onSendProgress: (enviados, total) {
          if (onProgreso != null && total > 0) {
            onProgreso(enviados / total);
          }
        },
      );
    } on DioException catch (e) {
      String detalle = '';
      if (e.response?.data != null) {
        try {
          final body = e.response!.data;
          if (body is Map) {
            detalle = (body['message'] as String?) ??
                (body['error'] as String?) ??
                '';
          } else if (body is String) {
            detalle = body;
          }
        } catch (_) {
          detalle = e.response?.data.toString() ?? '';
        }
      }
      final msg = detalle.isNotEmpty
          ? 'Cloudflare Worker: $detalle'
          : (e.message ?? 'error de red');
      throw ArchivoStorageException(
        'No se pudo subir (${e.response?.statusCode ?? 0}): $msg → $uploadUrl',
      );
    }

    // 2. URL pública (bucket r2.dev si está disponible, si no el Worker).
    final urlBase = EnvConfig.hasCloudflareR2
        ? EnvConfig.cloudflareR2BaseUrl.replaceAll(RegExp(r'/+$'), '')
        : workerBase;
    final urlPublica = '$urlBase/$objectKey';

    // 3. Registrar metadatos en Supabase.
    try {
      final row = await _client
          .from('archivos_asignatura')
          .insert({
            'usuario_id': user.id,
            'asignatura_id': asignaturaId,
            'nombre_archivo': nombreArchivo,
            'cloudflare_object_key': objectKey,
            'url_publica_o_firmada': urlPublica,
            'tamano_bytes': bytes.length,
            'tipo_mime': mime,
          })
          .select()
          .single();
      return ArchivoAsignaturaDto.fromMap(row);
    } catch (_) {
      // Rollback best-effort del objeto subido si falla el registro.
      await _borrarObjetoR2(objectKey);
      throw ArchivoStorageException(
        'El archivo se subió pero no se pudo registrar. Inténtalo de nuevo.',
      );
    }
  }

  /// Elimina el archivo (binario en R2 + metadatos en Supabase).
  Future<void> eliminarArchivo(ArchivoAsignaturaDto archivo) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw ArchivoStorageException('Sesión no válida.');
    }
    await _borrarObjetoR2(archivo.cloudflareObjectKey);
    await _client
        .from('archivos_asignatura')
        .delete()
        .eq('id', archivo.id)
        .eq('usuario_id', user.id);
  }

  Future<void> _borrarObjetoR2(String objectKey) async {
    if (!EnvConfig.hasR2Worker) return;
    final workerBase = EnvConfig.r2WorkerUrl.replaceAll(RegExp(r'/+$'), '');
    try {
      await _dio.delete<dynamic>('$workerBase/$objectKey');
    } on DioException {
      // Borrado best-effort: si falla, los metadatos igualmente se eliminan.
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static String _sanitizar(String nombre) {
    final limpio = nombre
        .replaceAll(RegExp(r'[^\w\.\-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    return limpio.isEmpty ? 'archivo' : limpio;
  }

  static String _inferirMime(String nombre) {
    final ext =
        nombre.contains('.') ? nombre.split('.').last.toLowerCase() : '';
    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'txt':
        return 'text/plain';
      case 'md':
        return 'text/markdown';
      case 'csv':
        return 'text/csv';
      case 'zip':
        return 'application/zip';
      default:
        return 'application/octet-stream';
    }
  }
}
