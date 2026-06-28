import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/sync/dominio_evento.dart';
import '../../../core/sync/sync_hub.dart';
import '../../../shared/models/db_models.dart';
import '../../../shared/utils/string_utils.dart';
import '../../perfil/application/perfil_provider.dart';
import '../infrastructure/ai_schedule_parser_service.dart';

/// Provider del servicio de análisis de horarios con IA.
final aiScheduleParserServiceProvider =
    Provider<AiScheduleParserService>((ref) {
  return AiScheduleParserService();
});

/// Guarda (o crea) las fechas de semestre en el perfil académico del usuario
/// para reutilizarlas en futuros escaneos. Invalida [perfilAcademicoProvider].
Future<void> guardarFechasSemestre({
  required DateTime inicio,
  required DateTime fin,
  required WidgetRef ref,
}) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) return;

  String fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  final existente = await client
      .from('perfil_academico_usuario')
      .select('id')
      .eq('usuario_id', user.id)
      .maybeSingle();

  if (existente != null) {
    await client.from('perfil_academico_usuario').update({
      'fecha_inicio_clases': fmt(inicio),
      'fecha_fin_clases': fmt(fin),
      'actualizado_en': DateTime.now().toIso8601String(),
    }).eq('usuario_id', user.id);
  } else {
    await client.from('perfil_academico_usuario').insert({
      'usuario_id': user.id,
      'semestre_actual': 1,
      'modalidad': 'presencial',
      'creditos_semestre_actual': 20,
      'horas_objetivo_estudio_semana': 14,
      'fecha_inicio_clases': fmt(inicio),
      'fecha_fin_clases': fmt(fin),
    });
  }

  ref.invalidate(perfilAcademicoProvider);
}

/// Resultado de la generación de horarios a partir del paquete de la IA.
class GeneracionHorarioResultado {
  const GeneracionHorarioResultado({
    required this.clasesGeneradas,
    required this.bloquesCreados,
    required this.asignaturasSinVincular,
  });

  final int clasesGeneradas;
  final int bloquesCreados;
  final List<String> asignaturasSinVincular;
}

/// Motor de generación: a partir del paquete ensamblado por la IA
/// (`{fecha_inicio_clases, fecha_fin_clases, horarios:[...]}`) crea las clases
/// como ocurrencias semanales fechadas en `horarios_academicos`, de modo que
/// aparezcan en el lienzo del plan semanal y en la pantalla de inicio.
///
/// Es idempotente: cada ocurrencia usa un `ics_uid` sintético, por lo que
/// re-escanear actualiza en lugar de duplicar (UNIQUE usuario_id,ics_uid).
Future<GeneracionHorarioResultado> generarHorariosDesdePaquete(
  Map<String, dynamic> paquete,
  List<AsignaturaDb> asignaturas,
  WidgetRef ref,
) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) {
    return const GeneracionHorarioResultado(
        clasesGeneradas: 0, bloquesCreados: 0, asignaturasSinVincular: []);
  }

  final inicio = DateTime.parse(paquete['fecha_inicio_clases'] as String);
  final fin = DateTime.parse(paquete['fecha_fin_clases'] as String);
  final horarios = (paquete['horarios'] as List).cast<Map<String, dynamic>>();

  final rows = <Map<String, dynamic>>[];
  final sinVincular = <String>{};
  const maxSemanas = 30;

  for (final h in horarios) {
    final dia = (h['dia_semana'] as num).toInt().clamp(1, 7);
    final hi = _parseHora(h['hora_inicio'] as String?);
    final hf = _parseHora(h['hora_fin'] as String?);
    if (hi == null || hf == null) continue;

    final nombre = (h['asignatura_nombre'] as String? ?? '').trim();
    final codigo = (h['asignatura_codigo'] as String?)?.trim();
    final tipo = (h['tipo'] as String? ?? '').trim();
    final aula = (h['aula'] as String? ?? '').trim();

    final asignaturaId = _matchAsignaturaId(codigo, nombre, asignaturas);
    if (asignaturaId == null && nombre.isNotEmpty) sinVincular.add(nombre);

    final claveBase = (codigo != null && codigo.isNotEmpty)
        ? normalizeSearch(codigo)
        : normalizeSearch(nombre);
    final temas = tipo.isNotEmpty ? '$nombre ($tipo)' : nombre;

    // Primera fecha >= inicio cuyo weekday coincide con dia.
    var fecha = DateTime(inicio.year, inicio.month, inicio.day);
    final delta = (dia - fecha.weekday + 7) % 7;
    fecha = fecha.add(Duration(days: delta));

    var semanas = 0;
    while (!fecha.isAfter(fin) && semanas < maxSemanas) {
      final inicioDt =
          DateTime(fecha.year, fecha.month, fecha.day, hi.$1, hi.$2);
      final finDt = DateTime(fecha.year, fecha.month, fecha.day, hf.$1, hf.$2);
      final stamp =
          '${fecha.year}${fecha.month.toString().padLeft(2, '0')}${fecha.day.toString().padLeft(2, '0')}';

      rows.add({
        'usuario_id': user.id,
        if (asignaturaId != null) 'asignatura_id': asignaturaId,
        'hora_inicio': inicioDt.toIso8601String(),
        'hora_fin': finDt.toIso8601String(),
        'tipo_actividad': 'clase',
        'es_fijo': false,
        'es_hito_inamovible': true,
        'dia_semana': dia,
        'prioridad': 'media',
        'temas': temas,
        if (aula.isNotEmpty) 'ubicacion': aula,
        'ics_uid': 'ai-$claveBase-$stamp-${hi.$1}${hi.$2}',
      });

      fecha = fecha.add(const Duration(days: 7));
      semanas++;
    }
  }

  if (rows.isNotEmpty) {
    // Upsert por lotes para idempotencia y eficiencia.
    await client
        .from('horarios_academicos')
        .upsert(rows, onConflict: 'usuario_id,ics_uid');
  }

  ref.read(syncHubProvider).dispatch(DominioEvento.planGuardado);

  return GeneracionHorarioResultado(
    clasesGeneradas: horarios.length,
    bloquesCreados: rows.length,
    asignaturasSinVincular: sinVincular.toList(),
  );
}

(int, int)? _parseHora(String? raw) {
  if (raw == null) return null;
  final partes = raw.trim().split(':');
  if (partes.length < 2) return null;
  final h = int.tryParse(partes[0]);
  final m = int.tryParse(partes[1]);
  if (h == null || m == null) return null;
  return (h.clamp(0, 23), m.clamp(0, 59));
}

String? _matchAsignaturaId(
    String? codigo, String nombre, List<AsignaturaDb> asignaturas) {
  if (codigo != null && codigo.isNotEmpty) {
    final c = normalizeSearch(codigo);
    for (final a in asignaturas) {
      if (a.codigo != null && normalizeSearch(a.codigo!) == c) return a.id;
    }
  }
  final n = normalizeSearch(nombre);
  if (n.isEmpty) return null;
  for (final a in asignaturas) {
    if (normalizeSearch(a.nombre) == n) return a.id;
  }
  for (final a in asignaturas) {
    final an = normalizeSearch(a.nombre);
    if (an.contains(n) || n.contains(an)) return a.id;
  }
  return null;
}
