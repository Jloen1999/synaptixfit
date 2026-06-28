import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/sync/dominio_evento.dart';
import '../../../core/sync/sync_hub.dart';
import '../domain/ics_evento.dart';
import 'ics_parser_service.dart';

class IcsSyncResult {
  final bool exitoso;
  final bool sinCoincidencia;
  final int examenes;
  final int entregas;
  final int clases;
  final String? error;
  final IcsParseResult? parseResult;

  const IcsSyncResult({
    required this.exitoso,
    required this.sinCoincidencia,
    required this.examenes,
    required this.entregas,
    required this.clases,
    this.error,
    this.parseResult,
  });
}

class IcsSyncService {
  final Ref _ref;
  IcsSyncService(this._ref);

  Future<IcsSyncResult> sincronizar({
    required String asignaturaId,
    required String asignaturaNombre,
    String? asignaturaCodigo,
    required String icsUrl,
    bool forzar = false,
  }) async {
    try {
      final parser = IcsParserService();
      final result = await parser.parsearYValidar(
        icsUrl,
        asignaturaNombre,
        asignaturaCodigo,
      );

      if (result.estado == EstadoCoincidencia.ninguna && !forzar) {
        return IcsSyncResult(
          exitoso: false,
          sinCoincidencia: true,
          examenes: 0,
          entregas: 0,
          clases: 0,
          parseResult: result,
        );
      }

      final eventos =
          forzar ? result.todosLosEventos : result.eventosCoincidentes;

      final client = Supabase.instance.client;
      final user = client.auth.currentUser!;
      var nExamenes = 0;
      var nEntregas = 0;
      var nClases = 0;

      for (final e in eventos) {
        final fin = e.dtEnd ?? e.dtStart.add(const Duration(hours: 1));

        if (e.tipo == 'examen' || e.tipo == 'entrega') {
          await client.from('entregas_examenes').upsert({
            'usuario_id': user.id,
            'asignatura_id': asignaturaId,
            'titulo': e.titulo,
            'tipo': e.tipo,
            'fecha_limite': e.dtStart.toIso8601String(),
            'dificultad': 'media',
            'ics_uid': e.uid,
          }, onConflict: 'usuario_id,ics_uid');

          // Además del registro académico, creamos el bloque en el lienzo del
          // plan semanal para que el examen/entrega sea visible en el calendario.
          final bloqueData = <String, dynamic>{
            'usuario_id': user.id,
            'asignatura_id': asignaturaId,
            'hora_inicio': e.dtStart.toIso8601String(),
            'hora_fin': fin.toIso8601String(),
            'tipo_actividad': e.tipo,
            'es_fijo': false,
            'es_hito_inamovible': true,
            'dia_semana': e.dtStart.weekday,
            'prioridad': 'media',
            'temas': e.titulo,
            'ics_uid': e.uid,
          };
          if (e.ubicacion != null) {
            bloqueData['ubicacion'] = e.ubicacion;
          }
          await client.from('horarios_academicos').upsert(
                bloqueData,
                onConflict: 'usuario_id,ics_uid',
              );

          if (e.tipo == 'examen') {
            nExamenes++;
          } else {
            nEntregas++;
          }
        } else {
          final mapData = <String, dynamic>{
            'usuario_id': user.id,
            'asignatura_id': asignaturaId,
            'hora_inicio': e.dtStart.toIso8601String(),
            'hora_fin': fin.toIso8601String(),
            'tipo_actividad': 'clase',
            'es_fijo': false,
            'es_hito_inamovible': true,
            'dia_semana': e.dtStart.weekday,
            'prioridad': 'media',
            'temas': e.titulo,
            'ics_uid': e.uid,
          };
          if (e.ubicacion != null) {
            mapData['ubicacion'] = e.ubicacion;
          }
          await client.from('horarios_academicos').upsert(
                mapData,
                onConflict: 'usuario_id,ics_uid',
              );
          nClases++;
        }
      }

      await client.from('asignaturas').update({
        'ultima_sincronizacion': DateTime.now().toIso8601String(),
      }).eq('id', asignaturaId);

      _ref.read(syncHubProvider).dispatch(DominioEvento.planGuardado);

      return IcsSyncResult(
        exitoso: true,
        sinCoincidencia: false,
        examenes: nExamenes,
        entregas: nEntregas,
        clases: nClases,
        parseResult: result,
      );
    } on PostgrestException catch (e) {
      return IcsSyncResult(
        exitoso: false,
        sinCoincidencia: false,
        examenes: 0,
        entregas: 0,
        clases: 0,
        error: 'Error de base de datos: ${e.message}',
      );
    } on DioException catch (e) {
      String msg;
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          msg = 'Tiempo de espera agotado al conectar con el servidor';
          break;
        case DioExceptionType.badResponse:
          msg = 'El servidor respondió con error ${e.response?.statusCode}';
          break;
        case DioExceptionType.connectionError:
          msg = 'No se pudo conectar al servidor del calendario';
          break;
        default:
          msg = 'Error de red: ${e.message ?? 'conexión rechazada'}';
      }
      return IcsSyncResult(
        exitoso: false,
        sinCoincidencia: false,
        examenes: 0,
        entregas: 0,
        clases: 0,
        error: msg,
      );
    } catch (e) {
      return IcsSyncResult(
        exitoso: false,
        sinCoincidencia: false,
        examenes: 0,
        entregas: 0,
        clases: 0,
        error: e.toString(),
      );
    }
  }
}

final icsSyncServiceProvider = Provider<IcsSyncService>((ref) {
  return IcsSyncService(ref);
});
