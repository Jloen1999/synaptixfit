import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum EstadoTareaGlobal { generando, completado, error }

class TareaGeneracionGlobal {
  final String id;
  final String titulo;
  final String tipo;
  EstadoTareaGlobal estado;
  final DateTime iniciadaEn;
  final VoidCallback onNavigate;

  TareaGeneracionGlobal({
    required this.id,
    required this.titulo,
    required this.tipo,
    required this.estado,
    required this.iniciadaEn,
    required this.onNavigate,
  });

  String get etiqueta => switch (tipo) {
        'resumen' => 'Resumen',
        'mapaMental' => 'Mapa mental',
        'cuestionario' => 'Cuestionario',
        _ => tipo,
      };

  bool get completado => estado == EstadoTareaGlobal.completado;
  bool get fallido => estado == EstadoTareaGlobal.error;
}

class GeneracionGlobalNotifier extends ChangeNotifier {
  final List<TareaGeneracionGlobal> _tareas = [];

  List<TareaGeneracionGlobal> get tareas => List.unmodifiable(_tareas);
  bool get hayTareasActivas =>
      _tareas.any((t) => t.estado == EstadoTareaGlobal.generando);
  TareaGeneracionGlobal? get tareaMasReciente {
    if (_tareas.isEmpty) return null;
    return _tareas.last;
  }

  TareaGeneracionGlobal registrar({
    required String titulo,
    required String tipo,
    required VoidCallback onNavigate,
  }) {
    final tarea = TareaGeneracionGlobal(
      id: _uid(),
      titulo: titulo,
      tipo: tipo,
      estado: EstadoTareaGlobal.generando,
      iniciadaEn: DateTime.now(),
      onNavigate: onNavigate,
    );
    _tareas.add(tarea);
    notifyListeners();
    return tarea;
  }

  void completarTarea(String id) {
    final idx = _tareas.indexWhere((t) => t.id == id);
    if (idx == -1) return;
    _tareas[idx].estado = EstadoTareaGlobal.completado;
    notifyListeners();

    Future.delayed(const Duration(seconds: 4), () {
      _eliminarSiCompletada(id);
    });
  }

  void fallarTarea(String id) {
    final idx = _tareas.indexWhere((t) => t.id == id);
    if (idx == -1) return;
    _tareas[idx].estado = EstadoTareaGlobal.error;
    notifyListeners();

    Future.delayed(const Duration(seconds: 4), () {
      _eliminarSiFallida(id);
    });
  }

  void _eliminarSiCompletada(String id) {
    final idx = _tareas.indexWhere((t) => t.id == id);
    if (idx == -1) return;
    if (_tareas[idx].estado != EstadoTareaGlobal.completado) return;
    _tareas.removeAt(idx);
    notifyListeners();
  }

  void _eliminarSiFallida(String id) {
    final idx = _tareas.indexWhere((t) => t.id == id);
    if (idx == -1) return;
    if (_tareas[idx].estado != EstadoTareaGlobal.error) return;
    _tareas.removeAt(idx);
    notifyListeners();
  }

  void eliminarTarea(String id) {
    _tareas.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  String _uid() =>
      'gen_${DateTime.now().millisecondsSinceEpoch}_${_tareas.length}';
}

final generacionGlobalProvider =
    ChangeNotifierProvider<GeneracionGlobalNotifier>(
        (ref) => GeneracionGlobalNotifier());

final hayTareasActivasProvider = Provider<bool>((ref) {
  return ref.watch(generacionGlobalProvider).hayTareasActivas;
});
