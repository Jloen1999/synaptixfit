import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/db_models.dart';
import '../domain/escanear_result.dart';
import '../infrastructure/scanner_service.dart';

/// Estados del flujo de escaneo.
enum EscanearEstado { idle, processing, done, error }

/// Estado completo del feature de escaneo.
class EscanearStateData {
  final EscanearEstado estado;
  final EscanearResult? resultado;
  final String? textoProcesado;

  const EscanearStateData({
    this.estado = EscanearEstado.idle,
    this.resultado,
    this.textoProcesado,
  });

  EscanearStateData copyWith({
    EscanearEstado? estado,
    EscanearResult? resultado,
    String? textoProcesado,
  }) {
    return EscanearStateData(
      estado: estado ?? this.estado,
      resultado: resultado ?? this.resultado,
      textoProcesado: textoProcesado ?? this.textoProcesado,
    );
  }
}

/// Provider del servicio de escaneo.
final scannerServiceProvider = Provider<ScannerService>((ref) {
  // En web/desktop retornamos la version no soportada.
  // En mobile se usaria MlKitScannerService cuando este configurado.
  return UnsupportedScannerService();
});

/// StateNotifier que orquesta el flujo completo de escaneo y guardado.
class EscanearNotifier extends StateNotifier<EscanearStateData> {
  EscanearNotifier(this._scannerService) : super(const EscanearStateData());

  final ScannerService _scannerService;

  /// Reinicia al estado inicial.
  void reset() {
    state = const EscanearStateData();
  }

  /// Procesa una imagen usando el servicio de escaneo real.
  Future<void> procesarImagen(String imagePath, {String? asignaturaId}) async {
    state = state.copyWith(estado: EscanearEstado.processing);

    try {
      final result = await _scannerService.scanText(imagePath);
      if (result.isSuccess) {
        state = state.copyWith(
          estado: EscanearEstado.done,
          resultado: result,
          textoProcesado: result.texto,
        );
      } else {
        state = state.copyWith(
          estado: EscanearEstado.error,
          resultado: result,
        );
      }
    } catch (e) {
      state = state.copyWith(
        estado: EscanearEstado.error,
        resultado: EscanearResult(error: 'Error al procesar imagen: $e'),
      );
    }
  }

  /// Procesa texto directo (sin camara, para flujo simplificado).
  Future<void> procesarTexto(String texto, {String? asignaturaId}) async {
    state = state.copyWith(estado: EscanearEstado.processing);

    try {
      final result = EscanearResult(
        texto: texto.trim(),
        asignaturaId: asignaturaId,
      );

      if (result.isSuccess) {
        state = state.copyWith(
          estado: EscanearEstado.done,
          resultado: result,
          textoProcesado: result.texto,
        );
      } else {
        state = state.copyWith(
          estado: EscanearEstado.error,
          resultado: const EscanearResult(error: 'No se pudo extraer texto.'),
        );
      }
    } catch (e) {
      state = state.copyWith(
        estado: EscanearEstado.error,
        resultado: EscanearResult(error: 'Error al procesar: $e'),
      );
    }
  }

  /// Guarda el texto procesado como apunte en Supabase.
  Future<ApunteDb?> guardarComoApunte({
    required String titulo,
    required String contenido,
    String? asignaturaId,
  }) async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return null;

    try {
      final data = await client
          .from('apuntes')
          .insert({
            'usuario_id': user.id,
            'titulo': titulo,
            'contenido': contenido,
            'asignatura_id': asignaturaId,
            'visibilidad': 'private',
            'es_nota_rapida': false,
          })
          .select()
          .single();

      return ApunteDb.fromMap(data);
    } catch (e) {
      state = state.copyWith(
        estado: EscanearEstado.error,
        resultado: EscanearResult(error: 'Error al guardar apunte: $e'),
      );
      return null;
    }
  }
}

/// Provider principal del feature de escaneo.
final escanearProvider =
    StateNotifierProvider<EscanearNotifier, EscanearStateData>(
  (ref) {
    final scannerService = ref.watch(scannerServiceProvider);
    return EscanearNotifier(scannerService);
  },
);
