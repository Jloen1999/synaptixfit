import 'package:freezed_annotation/freezed_annotation.dart';

part 'live_session_draft.freezed.dart';

/// Lo que solo sabe el teléfono de una sesión en curso y no debe perderse si
/// se cierra la app: el cronómetro de la serie (ADR 0030) y los ejercicios
/// cambiados solo para hoy (ADR 0031). Se borra al terminar o descartar.
@freezed
abstract class LiveSessionDraft with _$LiveSessionDraft {
  const factory LiveSessionDraft({
    /// Serie cronometrada: ejercicio planificado (nulo en sesión libre),
    /// número, desde cuándo corre (nulo si está en pausa) y segundos ya
    /// contados antes de la última pausa. Sin [timerSet], no hay cronómetro.
    String? timerPlannedExerciseId,
    int? timerSet,
    DateTime? timerSince,
    @Default(0) int timerBanked,

    /// Ejercicio planificado → el elegido para hoy en su lugar.
    @Default(<String, ExerciseSwap>{}) Map<String, ExerciseSwap> swaps,
  }) = _LiveSessionDraft;

  const LiveSessionDraft._();

  bool get isEmpty => timerSet == null && swaps.isEmpty;
}

/// Ejercicio elegido solo para esta sesión («Usar hoy»): la rutina no cambia.
@freezed
abstract class ExerciseSwap with _$ExerciseSwap {
  const factory ExerciseSwap({
    required String exerciseId,
    required String name,
    String? gifUrl,
    String? previewUrl,
  }) = _ExerciseSwap;
}
