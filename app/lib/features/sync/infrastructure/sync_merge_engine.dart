import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/operacion_pendiente_dto.dart';
import 'offline_queue_service.dart';

// ---------------------------------------------------------------------------
// Motor de resolucion de conflictos multi-dispositivo.
//
// Estrategia: last-write-wins basada en el campo `updated_at` del registro
// remoto. Si el registro en Supabase tiene un `updated_at` mas reciente que
// la operacion local, se descarta la operacion local. En caso contrario, se
// ejecuta la operacion pendiente.
// ---------------------------------------------------------------------------

class SyncMergeEngine {
  const SyncMergeEngine({
    required this.client,
    required this.queueService,
  });

  final SupabaseClient client;
  final OfflineQueueService queueService;

  // -------------------------------------------------------------------------
  // Resuelve un conflicto individual comparando timestamps.
  // Retorna true si la operacion local debe ejecutarse, false si debe
  // descartarse (el registro remoto es mas reciente).
  // -------------------------------------------------------------------------
  Future<bool> resolverConflicto(
    OperacionPendiente local,
    Map<String, dynamic>? remoto,
  ) async {
    // Si no hay registro remoto, no hay conflicto: ejecutar la operacion.
    if (remoto == null || remoto.isEmpty) return true;

    // Si la operacion es INSERT y ya existe un registro remoto, hay conflicto.
    if (local.operacion == 'INSERT') {
      // Si el remoto tiene updated_at mas reciente que nuestra creacion,
      // descartamos el INSERT local.
      final remotoUpdatedAt = remoto['actualizado_en'] ?? remoto['updated_at'];
      if (remotoUpdatedAt != null) {
        final remotoDate = _parseTimestamp(remotoUpdatedAt);
        if (remotoDate != null && remotoDate.isAfter(local.creadoEn)) {
          return false; // El remoto es mas reciente, descartar local.
        }
      }
      return true; // Ejecutar INSERT local.
    }

    // Para UPDATE y DELETE: comparar updated_at.
    final remotoUpdatedAt = remoto['actualizado_en'] ?? remoto['updated_at'];
    if (remotoUpdatedAt == null) return true; // Sin timestamp remoto, ejecutar.

    final remotoDate = _parseTimestamp(remotoUpdatedAt);
    if (remotoDate == null) return true;

    // Last-write-wins: si el remoto es mas reciente, descartar la operacion local.
    if (remotoDate.isAfter(local.creadoEn)) {
      return false; // Descartar: el remoto gana.
    }

    return true; // Ejecutar: la operacion local es mas reciente.
  }

  // -------------------------------------------------------------------------
  // Procesa toda la cola offline con resolucion de conflictos.
  // Para cada operacion pendiente:
  //   1. Consulta el estado actual del registro en Supabase.
  //   2. Resuelve el conflicto comparando timestamps.
  //   3. Ejecuta la operacion si gana, o la descarta si pierde.
  //
  // Retorna el numero de operaciones procesadas (ejecutadas + descartadas).
  // -------------------------------------------------------------------------
  Future<int> procesarColaCompleta({
    void Function(int procesadas, int total)? onProgress,
  }) async {
    final cola = queueService.cola;
    final total = cola.length;
    var procesadas = 0;

    // Usamos los indices reales de la cola para eliminar correctamente.
    var i = 0;
    while (i < queueService.longitud) {
      final raw = queueService.getRawAt(i);
      if (raw == null) {
        i++;
        continue;
      }

      final m = Map<String, dynamic>.from(raw);
      final reintentos = (m['reintentos'] as num?)?.toInt() ?? 0;

      // Si excedio reintentos, eliminar y continuar.
      if (reintentos >= OperacionPendiente.maxReintentos) {
        await queueService.eliminar(i);
        procesadas++;
        onProgress?.call(procesadas, total);
        continue;
      }

      final op = OperacionPendiente(
        id: m['id'] as String,
        tabla: m['tabla'] as String,
        operacion: m['operacion'] as String,
        datos: Map<String, dynamic>.from(m['datos'] as Map),
        creadoEn: DateTime.parse(m['creadoEn'] as String),
        identificador: m['identificador'] as String?,
        reintentos: reintentos,
      );

      try {
        // Consultar el estado actual en Supabase para detectar conflictos.
        Map<String, dynamic>? remoto;
        final identificador = op.identificador;

        if (identificador != null && identificador.isNotEmpty) {
          final remoteData = await client
              .from(op.tabla)
              .select()
              .eq('id', identificador)
              .maybeSingle();
          if (remoteData != null) {
            remoto = Map<String, dynamic>.from(remoteData);
          }
        }

        // Resolver conflicto.
        final debeEjecutar = await resolverConflicto(op, remoto);

        if (!debeEjecutar) {
          // Descartar operacion local: el remoto es mas reciente.
          await queueService.eliminar(i);
          procesadas++;
          onProgress?.call(procesadas, total);
          continue;
        }

        // Ejecutar la operacion.
        switch (op.operacion) {
          case 'INSERT':
            await client.from(op.tabla).insert(op.datos);
            break;
          case 'UPDATE':
            if (identificador != null) {
              await client
                  .from(op.tabla)
                  .update(op.datos)
                  .eq('id', identificador);
            }
            break;
          case 'DELETE':
            if (identificador != null) {
              await client.from(op.tabla).delete().eq('id', identificador);
            }
            break;
        }

        // Operacion ejecutada con exito, eliminar de la cola.
        await queueService.eliminar(i);
        procesadas++;
        onProgress?.call(procesadas, total);
      } catch (_) {
        // Error al procesar: incrementar reintentos y continuar.
        await queueService.incrementarReintentos(i, reintentos);
        i++;
      }
    }

    return procesadas;
  }

  // -------------------------------------------------------------------------
  // Parsea un timestamp de diversos formatos posibles.
  // -------------------------------------------------------------------------
  DateTime? _parseTimestamp(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}
