import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env_config.dart';

class EntregaWizard {
  const EntregaWizard({
    this.asignaturaId,
    this.asignaturaNombre,
    required this.titulo,
    required this.tipo,
    required this.fechaLimite,
    required this.dificultad,
  });

  final String? asignaturaId;
  final String? asignaturaNombre;
  final String titulo;
  final String tipo;
  final DateTime fechaLimite;
  final String dificultad;
}

class BloqueWizard {
  const BloqueWizard({
    required this.diaSemana,
    required this.horaInicio,
    required this.horaFin,
    this.asignaturaId,
    this.asignaturaNombre,
    this.tipoActividad = 'estudio',
    this.rutinaId,
    this.rutinaNombre,
    this.temas,
    this.esClaseFija = false,
    this.esSugerencia = false,
    this.aceptado = true,
  });

  final int diaSemana;
  final String horaInicio;
  final String horaFin;
  final String? asignaturaId;
  final String? asignaturaNombre;
  final String tipoActividad;
  final String? rutinaId;
  final String? rutinaNombre;
  final String? temas;
  final bool esClaseFija;
  final bool esSugerencia;
  final bool aceptado;
}

class WizardPlanState {
  const WizardPlanState({
    this.pasoActual = 0,
    this.entregas = const [],
    this.horarioFijo = const [],
    this.bloquesEstudio = const [],
    this.bloquesDeporte = const [],
    this.cargandoSugerencias = false,
    this.errorSugerencia,
    this.planId,
  });

  final int pasoActual;
  final List<EntregaWizard> entregas;
  final List<BloqueWizard> horarioFijo;
  final List<BloqueWizard> bloquesEstudio;
  final List<BloqueWizard> bloquesDeporte;
  final bool cargandoSugerencias;
  final String? errorSugerencia;
  final String? planId;

  WizardPlanState copyWith({
    int? pasoActual,
    List<EntregaWizard>? entregas,
    List<BloqueWizard>? horarioFijo,
    List<BloqueWizard>? bloquesEstudio,
    List<BloqueWizard>? bloquesDeporte,
    bool? cargandoSugerencias,
    String? errorSugerencia,
    bool clearError = false,
    String? planId,
  }) {
    return WizardPlanState(
      pasoActual: pasoActual ?? this.pasoActual,
      entregas: entregas ?? this.entregas,
      horarioFijo: horarioFijo ?? this.horarioFijo,
      bloquesEstudio: bloquesEstudio ?? this.bloquesEstudio,
      bloquesDeporte: bloquesDeporte ?? this.bloquesDeporte,
      cargandoSugerencias: cargandoSugerencias ?? this.cargandoSugerencias,
      errorSugerencia:
          clearError ? null : errorSugerencia ?? this.errorSugerencia,
      planId: planId ?? this.planId,
    );
  }
}

class WizardPlanNotifier extends StateNotifier<WizardPlanState> {
  WizardPlanNotifier() : super(const WizardPlanState());

  final _dio = Dio();

  void setPaso(int paso) {
    state = state.copyWith(pasoActual: paso);
  }

  void siguientePaso() {
    if (state.pasoActual < 3) {
      state = state.copyWith(pasoActual: state.pasoActual + 1);
    }
  }

  void anteriorPaso() {
    if (state.pasoActual > 0) {
      state = state.copyWith(pasoActual: state.pasoActual - 1);
    }
  }

  void addEntrega(EntregaWizard entrega) {
    state = state.copyWith(entregas: [...state.entregas, entrega]);
  }

  void removeEntrega(int index) {
    final lista = [...state.entregas];
    lista.removeAt(index);
    state = state.copyWith(entregas: lista);
  }

  void addHorarioFijo(BloqueWizard bloque) {
    state = state.copyWith(horarioFijo: [...state.horarioFijo, bloque]);
  }

  void removeHorarioFijo(int index) {
    final lista = [...state.horarioFijo];
    lista.removeAt(index);
    state = state.copyWith(horarioFijo: lista);
  }

  void acceptSugerenciaEstudio(int index) {
    final lista = [...state.bloquesEstudio];
    if (index < lista.length) {
      lista[index] = BloqueWizard(
        diaSemana: lista[index].diaSemana,
        horaInicio: lista[index].horaInicio,
        horaFin: lista[index].horaFin,
        asignaturaId: lista[index].asignaturaId,
        asignaturaNombre: lista[index].asignaturaNombre,
        tipoActividad: 'estudio',
        temas: lista[index].temas,
        esSugerencia: false,
        aceptado: !lista[index].aceptado,
      );
      state = state.copyWith(bloquesEstudio: lista);
    }
  }

  void removeSugerenciaEstudio(int index) {
    final lista = [...state.bloquesEstudio];
    lista.removeAt(index);
    state = state.copyWith(bloquesEstudio: lista);
  }

  void addBloqueEstudioManual(BloqueWizard bloque) {
    state = state.copyWith(bloquesEstudio: [...state.bloquesEstudio, bloque]);
  }

  void acceptSugerenciaDeporte(int index) {
    final lista = [...state.bloquesDeporte];
    if (index < lista.length) {
      lista[index] = BloqueWizard(
        diaSemana: lista[index].diaSemana,
        horaInicio: lista[index].horaInicio,
        horaFin: lista[index].horaFin,
        tipoActividad: 'deporte',
        rutinaId: lista[index].rutinaId,
        rutinaNombre: lista[index].rutinaNombre,
        esSugerencia: false,
        aceptado: !lista[index].aceptado,
      );
      state = state.copyWith(bloquesDeporte: lista);
    }
  }

  void removeSugerenciaDeporte(int index) {
    final lista = [...state.bloquesDeporte];
    lista.removeAt(index);
    state = state.copyWith(bloquesDeporte: lista);
  }

  void addBloqueDeporteManual(BloqueWizard bloque) {
    state = state.copyWith(bloquesDeporte: [...state.bloquesDeporte, bloque]);
  }

  void setPlanId(String id) {
    state = state.copyWith(planId: id);
  }

  void reset() {
    state = const WizardPlanState();
  }

  // ---------------------------------------------------------------------------
  // Auto-sugerencia de bloques de estudio con Gemini
  // ---------------------------------------------------------------------------
  Future<void> generarSugerenciasEstudio() async {
    if (state.entregas.isEmpty) {
      state = state.copyWith(
        bloquesEstudio: const [],
        cargandoSugerencias: false,
      );
      return;
    }

    state = state.copyWith(cargandoSugerencias: true, clearError: true);

    if (EnvConfig.hasGeminiApiKey) {
      await _generarConGemini();
    } else {
      _generarManual();
    }
  }

  Future<void> _generarConGemini() async {
    try {
      final horariosOcupados = _formatearHorariosOcupados();
      final entregasStr = state.entregas
          .map((e) =>
              '- ${e.titulo} (${e.tipo}, dificultad: ${e.dificultad}, fecha: ${e.fechaLimite.toIso8601String().split('T')[0]})')
          .join('\n');

      final prompt = '''
Eres un asistente de planificación académica para estudiantes.
Genera bloques de estudio semanal realistas y breves.
Responde SOLO con un array JSON, sin texto adicional.
Formato exacto requerido:

[
  {"dia": 1, "hora_inicio": "17:00", "hora_fin": "18:30", "asignatura": "Álgebra", "tema": "Matrices"},
  {"dia": 3, "hora_inicio": "16:00", "hora_fin": "17:30", "asignatura": "Historia", "tema": "Revolución"}
]

Reglas:
- dia: 1=Lunes, 2=Martes, ..., 7=Domingo
- Cada bloque debe durar entre 1h y 2h
- Prioriza los 2-3 días antes de cada fecha límite
- Evita estos horarios ya ocupados:
$horariosOcupados
- Asigna máximo 2 bloques por día
- Si hay 3 o menos entregas, genera 4-6 bloques en total
- Si hay más de 3 entregas, genera 6-10 bloques en total
- Los temas deben ser específicos y breves (máx 4 palabras)

Entregas y exámenes del usuario:
$entregasStr
''';

      final response = await _dio.post<Map<String, dynamic>>(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent',
        options: Options(headers: {
          'Content-Type': 'application/json',
          'X-goog-api-key': EnvConfig.geminiApiKey,
        }),
        data: {
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ]
        },
      );

      final data = response.data;
      final candidates = (data?['candidates'] as List<dynamic>?)
              ?.cast<Map<String, dynamic>>() ??
          const <Map<String, dynamic>>[];
      final text = candidates.isNotEmpty ? candidates.first['content'] : null;
      final parts = (text is Map<String, dynamic>)
          ? (text['parts'] as List<dynamic>?)
          : null;
      final partMaps =
          parts?.cast<Map<String, dynamic>>() ?? const <Map<String, dynamic>>[];
      final raw =
          partMaps.isNotEmpty ? partMaps.first['text']?.toString() : null;

      if (raw == null || raw.trim().isEmpty) {
        _generarManual();
        return;
      }

      final jsonStr = _extraerJson(raw);
      final parsed = jsonDecode(jsonStr) as List<dynamic>;
      final bloques = <BloqueWizard>[];

      for (final b in parsed) {
        final map = b as Map<String, dynamic>;
        final dia = (map['dia'] as num).toInt();
        bloques.add(BloqueWizard(
          diaSemana: dia.clamp(1, 7),
          horaInicio: map['hora_inicio'] as String,
          horaFin: map['hora_fin'] as String,
          asignaturaNombre: map['asignatura'] as String?,
          tipoActividad: 'estudio',
          temas: map['tema'] as String?,
          esSugerencia: true,
          aceptado: true,
        ));
      }

      state = state.copyWith(
        bloquesEstudio: bloques,
        cargandoSugerencias: false,
      );
    } catch (_) {
      _generarManual();
    }
  }

  void _generarManual() {
    final bloques = <BloqueWizard>[];
    final diasOcupados = <int, List<List<int>>>{};
    for (final h in state.horarioFijo) {
      diasOcupados.putIfAbsent(h.diaSemana, () => []);
      final ini = _horaAMinutos(h.horaInicio);
      final fin = _horaAMinutos(h.horaFin);
      diasOcupados[h.diaSemana]!.add([ini, fin]);
    }

    for (final entrega in state.entregas) {
      final fechaObj = entrega.fechaLimite;
      final diaLimite = fechaObj.weekday;

      for (var offset = -3; offset <= -1; offset++) {
        var dia = diaLimite + offset;
        if (dia < 1) dia += 7;
        if (dia > 7) dia -= 7;

        final bloquesDelDia = bloques.where((b) => b.diaSemana == dia).length;
        if (bloquesDelDia >= 2) continue;

        final ocupados = diasOcupados[dia] ?? [];
        final franja = _buscarFranjaLibre(ocupados, bloquesDelDia);
        if (franja == null) continue;

        bloques.add(BloqueWizard(
          diaSemana: dia,
          horaInicio: franja[0],
          horaFin: franja[1],
          asignaturaNombre: entrega.asignaturaNombre,
          tipoActividad: 'estudio',
          temas: 'Repaso ${entrega.titulo}',
          esSugerencia: true,
          aceptado: true,
        ));
      }
    }

    state = state.copyWith(
      bloquesEstudio: bloques,
      cargandoSugerencias: false,
    );
  }

  // ---------------------------------------------------------------------------
  // Auto-sugerencia de bloques deportivos
  // ---------------------------------------------------------------------------
  Future<void> generarSugerenciasDeporte() async {
    state = state.copyWith(cargandoSugerencias: true, clearError: true);

    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) {
        _generarDeporteDefault();
        return;
      }

      final rutinasData = await client
          .from('rutinas')
          .select()
          .eq('usuario_id', user.id)
          .eq('estado', 'activo')
          .order('creado_en', ascending: false)
          .limit(5);

      final rutinas =
          (rutinasData as List).map((r) => r as Map<String, dynamic>).toList();

      final estudioPorDia = <int, double>{};
      for (final b in state.bloquesEstudio) {
        if (b.aceptado) {
          final mins = _duracionEnMinutos(b.horaInicio, b.horaFin);
          estudioPorDia[b.diaSemana] =
              (estudioPorDia[b.diaSemana] ?? 0) + (mins / 60.0);
        }
      }

      final bloques = <BloqueWizard>[];

      if (rutinas.isNotEmpty && EnvConfig.hasGeminiApiKey) {
        await _generarDeporteConGemini(rutinas, estudioPorDia, bloques);
      } else {
        _generarDeporteManual(rutinas, estudioPorDia, bloques);
      }

      state = state.copyWith(
        bloquesDeporte: bloques,
        cargandoSugerencias: false,
      );
    } catch (_) {
      _generarDeporteDefault();
    }
  }

  Future<void> _generarDeporteConGemini(
    List<Map<String, dynamic>> rutinas,
    Map<int, double> estudioPorDia,
    List<BloqueWizard> bloques,
  ) async {
    final estudioStr = estudioPorDia.entries
        .map((e) => 'Día ${e.key}: ${e.value.toStringAsFixed(1)}h estudio')
        .join('\n');

    final rutinasStr = rutinas
        .map((r) =>
            '- ${r['nombre']}: ${r['objetivo']}, ${r['cantidad_ejercicios']} ejercicios, ${r['duracion_semanas']} semanas')
        .join('\n');

    final horariosOcupados = _formatearHorariosOcupados();

    final prompt = '''
Eres un entrenador deportivo que equilibra estudio y ejercicio.
Responde SOLO con un array JSON, sin texto adicional.

[
  {"dia": 4, "hora_inicio": "18:00", "hora_fin": "19:00", "rutina": "Rutina de Torso"}
]

Reglas:
- dia: 1=Lunes, 2=Martes, ..., 7=Domingo
- Cada bloque dura entre 30 min y 1.5 h
- Coloca el deporte en días con >= 3h de estudio, al final del día (después de 17:00)
- Si no hay días con >= 3h de estudio, elige 2-3 días libres después de las 17:00
- Evita estos horarios ya ocupados:
$horariosOcupados
- Genera 2-4 bloques máximo
- No asignes más de 1 bloque deportivo por día

Carga de estudio por día:
$estudioStr

Rutinas disponibles:
$rutinasStr
''';

    final response = await _dio.post<Map<String, dynamic>>(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent',
      options: Options(headers: {
        'Content-Type': 'application/json',
        'X-goog-api-key': EnvConfig.geminiApiKey,
      }),
      data: {
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ]
      },
    );

    final data = response.data;
    final candidates =
        (data?['candidates'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
            const <Map<String, dynamic>>[];
    final text = candidates.isNotEmpty ? candidates.first['content'] : null;
    final parts = (text is Map<String, dynamic>)
        ? (text['parts'] as List<dynamic>?)
        : null;
    final partMaps =
        parts?.cast<Map<String, dynamic>>() ?? const <Map<String, dynamic>>[];
    final raw = partMaps.isNotEmpty ? partMaps.first['text']?.toString() : null;

    if (raw == null || raw.trim().isEmpty) {
      _generarDeporteManual(rutinas, estudioPorDia, bloques);
      return;
    }

    final jsonStr = _extraerJson(raw);
    final parsed = jsonDecode(jsonStr) as List<dynamic>;

    for (final b in parsed) {
      final map = b as Map<String, dynamic>;
      final dia = (map['dia'] as num).toInt();
      final rutinaNombre = map['rutina'] as String?;
      final rutinaMatch = rutinas.where(
        (r) => r['nombre'] == rutinaNombre,
      );
      final rutinaId =
          rutinaMatch.isNotEmpty ? rutinaMatch.first['id'] as String? : null;

      bloques.add(BloqueWizard(
        diaSemana: dia.clamp(1, 7),
        horaInicio: map['hora_inicio'] as String,
        horaFin: map['hora_fin'] as String,
        tipoActividad: 'deporte',
        rutinaId: rutinaId,
        rutinaNombre: rutinaNombre,
        esSugerencia: true,
        aceptado: true,
      ));
    }
  }

  void _generarDeporteManual(
    List<Map<String, dynamic>> rutinas,
    Map<int, double> estudioPorDia,
    List<BloqueWizard> bloques,
  ) {
    final diasConMuchoEstudio = estudioPorDia.entries
        .where((e) => e.value >= 3.0)
        .map((e) => e.key)
        .toSet();

    if (diasConMuchoEstudio.isEmpty && estudioPorDia.isNotEmpty) {
      diasConMuchoEstudio.addAll(estudioPorDia.entries
          .where((e) => e.value >= 1.5)
          .map((e) => e.key)
          .take(3));
    }

    if (diasConMuchoEstudio.isEmpty) {
      for (var d = 1; d <= 7; d++) {
        if (d != 1 && d != 7) diasConMuchoEstudio.add(d);
      }
    }

    int rutinaIdx = 0;
    for (final dia in diasConMuchoEstudio.take(4)) {
      final deporteEnDia = bloques.where((b) => b.diaSemana == dia).length;
      if (deporteEnDia >= 1) continue;

      String horaInicio = '17:00';
      String horaFin = '18:00';

      String? rutinaNombre;
      String? rutinaId;
      if (rutinas.isNotEmpty) {
        final r = rutinas[rutinaIdx % rutinas.length];
        rutinaNombre = r['nombre'] as String?;
        rutinaId = r['id'] as String?;
        rutinaIdx++;
      }

      bloques.add(BloqueWizard(
        diaSemana: dia,
        horaInicio: horaInicio,
        horaFin: horaFin,
        tipoActividad: 'deporte',
        rutinaId: rutinaId,
        rutinaNombre: rutinaNombre,
        esSugerencia: true,
        aceptado: true,
      ));
    }
  }

  void _generarDeporteDefault() {
    state = state.copyWith(
      bloquesDeporte: const [],
      cargandoSugerencias: false,
    );
  }

  // ---------------------------------------------------------------------------
  // Utilidades
  // ---------------------------------------------------------------------------
  String _formatearHorariosOcupados() {
    final buf = StringBuffer();
    for (final h in state.horarioFijo) {
      buf.writeln('Día ${h.diaSemana}: ${h.horaInicio}-${h.horaFin}');
    }
    return buf.toString();
  }

  int _horaAMinutos(String hora) {
    final parts = hora.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  double _duracionEnMinutos(String inicio, String fin) {
    return (_horaAMinutos(fin) - _horaAMinutos(inicio)).toDouble();
  }

  List<String>? _buscarFranjaLibre(
      List<List<int>> ocupados, int bloquesDelDia) {
    const franjas = [
      ['15:00', '16:30'],
      ['16:30', '18:00'],
      ['18:00', '19:30'],
      ['19:30', '21:00'],
      ['10:00', '11:30'],
      ['12:00', '13:30'],
    ];

    for (final f in franjas) {
      final ini = _horaAMinutos(f[0]);
      final fin = _horaAMinutos(f[1]);
      bool libre = true;
      for (final o in ocupados) {
        if (!(fin <= o[0] || ini >= o[1])) {
          libre = false;
          break;
        }
      }
      if (libre) return [f[0], f[1]];
    }
    return null;
  }

  String _extraerJson(String raw) {
    final start = raw.indexOf('[');
    final end = raw.lastIndexOf(']');
    if (start != -1 && end != -1 && end > start) {
      return raw.substring(start, end + 1);
    }
    return raw;
  }
}

final wizardPlanProvider =
    StateNotifierProvider<WizardPlanNotifier, WizardPlanState>((ref) {
  return WizardPlanNotifier();
});
