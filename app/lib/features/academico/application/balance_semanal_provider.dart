import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BalanceSemanalDto {
  const BalanceSemanalDto({
    required this.horasEstudioPlaneadas,
    required this.horasEstudioReales,
    required this.horasDeportePlaneadas,
    required this.horasDeporteReales,
    required this.estado,
    required this.mensaje,
    required this.sugerencia,
  });

  final double horasEstudioPlaneadas;
  final double horasEstudioReales;
  final double horasDeportePlaneadas;
  final double horasDeporteReales;
  final String estado;
  final String mensaje;
  final String sugerencia;
}

final balanceSemanalProvider = FutureProvider<BalanceSemanalDto>((ref) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) {
    return const BalanceSemanalDto(
      horasEstudioPlaneadas: 0,
      horasEstudioReales: 0,
      horasDeportePlaneadas: 0,
      horasDeporteReales: 0,
      estado: 'inactivo',
      mensaje: 'Sin datos',
      sugerencia: 'Crea tu plan semanal para empezar.',
    );
  }

  final now = DateTime.now();
  final lunes = now.subtract(Duration(days: now.weekday - 1));
  final domingo = lunes.add(const Duration(days: 6));
  final lunesStr = lunes.toIso8601String().split('T')[0];
  final domingoStr =
      DateTime(domingo.year, domingo.month, domingo.day, 23, 59, 59)
          .toIso8601String();

  final horariosData = await client
      .from('horarios_academicos')
      .select('tipo_actividad, hora_inicio, hora_fin, completado')
      .eq('usuario_id', user.id)
      .gte('hora_inicio', lunesStr)
      .lte('hora_inicio', domingoStr);

  double estudioPlaneado = 0;
  double deportePlaneado = 0;
  double estudioReal = 0;
  double deporteReal = 0;

  for (final h in (horariosData as List)) {
    final inicio = DateTime.parse(h['hora_inicio'] as String);
    final fin = DateTime.parse(h['hora_fin'] as String);
    final duracion = fin.difference(inicio).inMinutes / 60.0;
    final tipo = h['tipo_actividad'] as String? ?? 'estudio';
    final completado = h['completado'] as bool? ?? false;

    if (tipo == 'deporte') {
      deportePlaneado += duracion;
      if (completado) deporteReal += duracion;
    } else {
      estudioPlaneado += duracion;
      if (completado) estudioReal += duracion;
    }
  }

  final total = estudioPlaneado + deportePlaneado;
  String estado;
  String mensaje;
  String sugerencia;

  if (total == 0) {
    estado = 'inactivo';
    mensaje = 'Sin bloques esta semana';
    sugerencia = 'Crea bloques de estudio y deporte para ver tu balance.';
  } else if (deportePlaneado == 0 && estudioPlaneado > 0) {
    estado = 'carga_estudio';
    mensaje = 'Semana muy densa';
    sugerencia =
        'Tienes ${estudioPlaneado.toStringAsFixed(1)}h de estudio y 0h de deporte. ¡No olvides moverte!';
  } else if (estudioPlaneado == 0 && deportePlaneado > 0) {
    estado = 'carga_deporte';
    mensaje = '¡Excelente actividad física!';
    sugerencia =
        'No olvides dedicar tiempo al estudio para mantener el equilibrio.';
  } else {
    final ratio = deportePlaneado / (estudioPlaneado + deportePlaneado);
    if (ratio >= 0.3 && ratio <= 0.5) {
      estado = 'equilibrado';
      mensaje = '¡Equilibrio perfecto!';
      sugerencia =
          'Tu semana tiene un gran balance entre estudio y deporte. ¡Sigue así!';
    } else if (ratio < 0.3) {
      estado = 'carga_estudio';
      mensaje = 'Predomina el estudio';
      sugerencia =
          'Intenta añadir al menos 2h de deporte esta semana para mejorar tu balance.';
    } else {
      estado = 'carga_deporte';
      mensaje = 'Predomina el deporte';
      sugerencia =
          'Asegúrate de reservar suficiente tiempo para el estudio también.';
    }
  }

  return BalanceSemanalDto(
    horasEstudioPlaneadas: estudioPlaneado,
    horasEstudioReales: estudioReal,
    horasDeportePlaneadas: deportePlaneado,
    horasDeporteReales: deporteReal,
    estado: estado,
    mensaje: mensaje,
    sugerencia: sugerencia,
  );
});
