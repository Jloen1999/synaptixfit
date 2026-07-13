import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/fuente_estudio.dart';
import '../domain/mapa_mental.dart';
import '../infrastructure/estudio_ia_service.dart';

enum TipoGeneracion { resumen, mapaMental, cuestionario }

enum FormatoCuestionario { tarjetas, simulacro }

enum EstadoGeneracion { inactivo, cargando, completado, error }

class PreguntaGenerada {
  final String id;
  final String tipo;
  String enunciado;
  final List<String> opciones;
  String respuestaCorrecta;
  final String? explicacion;

  String? respuestaUsuario;
  bool? esCorrecta;

  PreguntaGenerada({
    required this.id,
    required this.tipo,
    required this.enunciado,
    required this.opciones,
    required this.respuestaCorrecta,
    this.explicacion,
    this.respuestaUsuario,
    this.esCorrecta,
  });

  factory PreguntaGenerada.desdeIa(Map<String, dynamic> raw) {
    final tipo = (raw['tipo'] as String?) ?? 'opcion_multiple';
    final resp = (raw['respuesta_correcta'] as String?) ?? '';
    return PreguntaGenerada(
      id: _uid(),
      tipo: tipo,
      enunciado: (raw['enunciado'] as String?) ?? '',
      opciones: tipo == 'opcion_multiple'
          ? ((raw['opciones'] as List<dynamic>?)?.cast<String>() ?? [])
          : [resp],
      respuestaCorrecta: resp,
      explicacion: raw['explicacion'] as String?,
    );
  }

  factory PreguntaGenerada.desdeTarjeta(Map<String, dynamic> raw) {
    return PreguntaGenerada(
      id: _uid(),
      tipo: 'tarjeta',
      enunciado: (raw['pregunta'] as String?) ?? '',
      opciones: const [],
      respuestaCorrecta: (raw['respuesta'] as String?) ?? '',
      explicacion: raw['explicacion'] as String?,
    );
  }

  bool get esOpcionMultiple => tipo == 'opcion_multiple';
  bool get esTarjeta => tipo == 'tarjeta';

  static String _uid() {
    final r = math.Random();
    return 'efimera_${DateTime.now().millisecondsSinceEpoch}_${r.nextInt(99999)}';
  }
}

class ArtefactoEfimeroState {
  final TipoGeneracion tipo;
  final FormatoCuestionario? formatoCuestionario;
  final EstadoGeneracion estado;
  final String? contenido;
  final MapaMental? mapa;
  final List<PreguntaGenerada> preguntas;
  final String? error;
  final String? asignaturaId;
  final int? puntuacion;
  final int? totalPreguntas;
  final bool modoRevision;
  final String? tituloPersonalizado;
  final String? tareaGlobalId;

  const ArtefactoEfimeroState({
    this.tipo = TipoGeneracion.resumen,
    this.formatoCuestionario,
    this.estado = EstadoGeneracion.inactivo,
    this.contenido,
    this.mapa,
    this.preguntas = const [],
    this.error,
    this.asignaturaId,
    this.puntuacion,
    this.totalPreguntas,
    this.modoRevision = false,
    this.tituloPersonalizado,
    this.tareaGlobalId,
  });

  ArtefactoEfimeroState copyWith({
    TipoGeneracion? tipo,
    FormatoCuestionario? formatoCuestionario,
    EstadoGeneracion? estado,
    String? contenido,
    MapaMental? mapa,
    List<PreguntaGenerada>? preguntas,
    String? error,
    String? asignaturaId,
    int? puntuacion,
    int? totalPreguntas,
    bool? modoRevision,
    String? tituloPersonalizado,
    String? tareaGlobalId,
    bool limpiarFormatoCuestionario = false,
  }) {
    return ArtefactoEfimeroState(
      tipo: tipo ?? this.tipo,
      formatoCuestionario: limpiarFormatoCuestionario
          ? null
          : (formatoCuestionario ?? this.formatoCuestionario),
      estado: estado ?? this.estado,
      contenido: contenido ?? this.contenido,
      mapa: mapa ?? this.mapa,
      preguntas: preguntas ?? this.preguntas,
      error: error ?? this.error,
      asignaturaId: asignaturaId ?? this.asignaturaId,
      puntuacion: puntuacion ?? this.puntuacion,
      totalPreguntas: totalPreguntas ?? this.totalPreguntas,
      modoRevision: modoRevision ?? this.modoRevision,
      tituloPersonalizado: tituloPersonalizado ?? this.tituloPersonalizado,
      tareaGlobalId: tareaGlobalId ?? this.tareaGlobalId,
    );
  }

  int get aciertos => preguntas.where((p) => p.esCorrecta == true).length;

  String get tituloEfectivo => tituloPersonalizado ?? _tituloPorDefecto();

  String _tituloPorDefecto() => switch (tipo) {
        TipoGeneracion.resumen => 'Resumen',
        TipoGeneracion.mapaMental => 'Mapa mental',
        TipoGeneracion.cuestionario => 'Cuestionario',
      };
}

class ArtefactoEfimeroNotifier extends StateNotifier<ArtefactoEfimeroState> {
  ArtefactoEfimeroNotifier() : super(const ArtefactoEfimeroState());

  final EstudioIaService _ia = EstudioIaService();
  List<FuenteEstudio>? _fuentes;

  void setFuentes(List<FuenteEstudio> fuentes) {
    _fuentes = fuentes;
  }

  bool _cancelado = false;

  void cancelar() {
    _cancelado = true;
    state = state.copyWith(estado: EstadoGeneracion.inactivo, error: null);
  }

  void setTareaGlobalId(String id) {
    state = state.copyWith(tareaGlobalId: id);
  }

  Future<void> iniciarYGenerar(
    List<FuenteEstudio> fuentes,
    TipoGeneracion tipo, {
    String? asignaturaId,
    String? tareaGlobalId,
  }) async {
    _cancelado = false;
    _fuentes = fuentes;

    if (tipo == TipoGeneracion.cuestionario) {
      state = state.copyWith(
        tipo: tipo,
        estado: EstadoGeneracion.inactivo,
        error: null,
        asignaturaId: asignaturaId,
        tareaGlobalId: tareaGlobalId,
        limpiarFormatoCuestionario: true,
      );
      return;
    }

    state = state.copyWith(
      tipo: tipo,
      estado: EstadoGeneracion.cargando,
      error: null,
      asignaturaId: asignaturaId,
      tareaGlobalId: tareaGlobalId,
      limpiarFormatoCuestionario: true,
    );

    try {
      switch (tipo) {
        case TipoGeneracion.resumen:
          final json = await _ia.resumirMulti(fuentes);
          state = state.copyWith(
            estado: EstadoGeneracion.completado,
            contenido: json['contenido_markdown'] as String?,
            tituloPersonalizado: json['titulo_personalizado'] as String?,
          );
        case TipoGeneracion.mapaMental:
          final json = await _ia.mapaMentalMulti(fuentes);
          final markdown = json['contenido_markdown'] as String? ?? '';
          final titulo = json['titulo_personalizado'] as String?;
          final mapa =
              _ia.parsearMarkdownAMapaMental(markdown, titulo ?? 'Mapa mental');
          state = state.copyWith(
            estado: EstadoGeneracion.completado,
            mapa: mapa,
            contenido: markdown,
            tituloPersonalizado: titulo,
          );
        case TipoGeneracion.cuestionario:
          break;
      }
    } on EstudioIaException catch (e) {
      state = state.copyWith(estado: EstadoGeneracion.error, error: e.message);
    } catch (e) {
      state =
          state.copyWith(estado: EstadoGeneracion.error, error: 'Error: $e');
    }
  }

  Future<void> generarResumen() async {
    state = state.copyWith(
      tipo: TipoGeneracion.resumen,
      estado: EstadoGeneracion.cargando,
      error: null,
      limpiarFormatoCuestionario: true,
    );
    try {
      final json = await _ia.resumirMulti(const []);
      state = state.copyWith(
        estado: EstadoGeneracion.completado,
        contenido: json['contenido_markdown'] as String?,
        tituloPersonalizado: json['titulo_personalizado'] as String?,
      );
    } on EstudioIaException catch (e) {
      state = state.copyWith(estado: EstadoGeneracion.error, error: e.message);
    } catch (e) {
      state =
          state.copyWith(estado: EstadoGeneracion.error, error: 'Error: $e');
    }
  }

  Future<void> generarMapaMental() async {
    state = state.copyWith(
      tipo: TipoGeneracion.mapaMental,
      estado: EstadoGeneracion.cargando,
      error: null,
      limpiarFormatoCuestionario: true,
    );
    try {
      final json = await _ia.mapaMentalMulti(const []);
      final markdown = json['contenido_markdown'] as String? ?? '';
      final titulo = json['titulo_personalizado'] as String?;
      final mapa =
          _ia.parsearMarkdownAMapaMental(markdown, titulo ?? 'Mapa mental');
      state = state.copyWith(
        estado: EstadoGeneracion.completado,
        mapa: mapa,
        contenido: markdown,
        tituloPersonalizado: titulo,
      );
    } on EstudioIaException catch (e) {
      state = state.copyWith(estado: EstadoGeneracion.error, error: e.message);
    } catch (e) {
      state =
          state.copyWith(estado: EstadoGeneracion.error, error: 'Error: $e');
    }
  }

  Future<void> generarCuestionario() async {
    _cancelado = false;
    state = state.copyWith(
      tipo: TipoGeneracion.cuestionario,
      estado: EstadoGeneracion.cargando,
      error: null,
      limpiarFormatoCuestionario: true,
    );
    try {
      final json = await _ia.generarCuestionarioMulti(_fuentes ?? []);
      if (_cancelado) return;
      final tarjetasRaw = json['tarjetas'] as List<dynamic>? ?? [];
      final preguntas = tarjetasRaw
          .map((r) => PreguntaGenerada.desdeTarjeta(r as Map<String, dynamic>))
          .toList();
      if (_cancelado) return;
      state = state.copyWith(
        estado: EstadoGeneracion.completado,
        preguntas: preguntas,
        tituloPersonalizado: json['titulo_personalizado'] as String?,
      );
    } on EstudioIaException catch (e) {
      if (_cancelado) return;
      state = state.copyWith(estado: EstadoGeneracion.error, error: e.message);
    } catch (e) {
      if (_cancelado) return;
      state =
          state.copyWith(estado: EstadoGeneracion.error, error: 'Error: $e');
    }
  }

  void setFormato(FormatoCuestionario f) {
    state = state.copyWith(formatoCuestionario: f);
  }

  void responderPregunta(int indice, String respuesta) {
    final preguntas = List<PreguntaGenerada>.from(state.preguntas);
    if (indice < 0 || indice >= preguntas.length) return;
    final p = preguntas[indice];
    p.respuestaUsuario = respuesta;
    p.esCorrecta = respuesta.trim().toLowerCase() ==
        p.respuestaCorrecta.trim().toLowerCase();
  }

  void finalizarSimulacro() {
    final preguntas = state.preguntas;
    final aciertos = preguntas.where((p) => p.esCorrecta == true).length;
    state =
        state.copyWith(puntuacion: aciertos, totalPreguntas: preguntas.length);
  }

  void activarModoRevision() {
    state = state.copyWith(modoRevision: true);
  }

  void regenerar() {
    state = state.copyWith(estado: EstadoGeneracion.cargando, error: null);
    switch (state.tipo) {
      case TipoGeneracion.resumen:
        generarResumen();
      case TipoGeneracion.mapaMental:
        generarMapaMental();
      case TipoGeneracion.cuestionario:
        generarCuestionario();
    }
  }

  Future<void> generarCuestionarioSimulacro() async {
    _cancelado = false;
    state = state.copyWith(
      tipo: TipoGeneracion.cuestionario,
      estado: EstadoGeneracion.cargando,
      error: null,
    );
    try {
      final json = await _ia.generarPracticaMulti(_fuentes ?? []);
      if (_cancelado) return;
      final raw = json['preguntas'] as List<dynamic>? ?? [];
      final preguntas = raw
          .map((r) => PreguntaGenerada.desdeIa(r as Map<String, dynamic>))
          .toList();
      if (_cancelado) return;
      state = state.copyWith(
        estado: EstadoGeneracion.completado,
        preguntas: preguntas,
        tituloPersonalizado: json['titulo_personalizado'] as String?,
      );
    } on EstudioIaException catch (e) {
      if (_cancelado) return;
      state = state.copyWith(estado: EstadoGeneracion.error, error: e.message);
    } catch (e) {
      if (_cancelado) return;
      state =
          state.copyWith(estado: EstadoGeneracion.error, error: 'Error: $e');
    }
  }

  void limpiar() {
    state = const ArtefactoEfimeroState();
  }
}

final artefactoEfimeroProvider =
    StateNotifierProvider<ArtefactoEfimeroNotifier, ArtefactoEfimeroState>(
  (ref) => ArtefactoEfimeroNotifier(),
);
