import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/guia_docente_dto.dart';
import '../infrastructure/documento_ia_repository.dart';
import '../infrastructure/guia_docente_ia_service.dart';
import 'documento_ia_provider.dart';

final guiaDocenteIaServiceProvider =
    Provider<GuiaDocenteIaService>((ref) => GuiaDocenteIaService());

final guiaDocenteDtoProvider =
    FutureProvider.family<GuiaDocenteDto?, String>((ref, asignaturaId) async {
  final repo = ref.read(documentoIaRepositoryProvider);
  final doc = await repo.obtener(
    fuenteTipo: 'guia_docente',
    fuenteId: asignaturaId,
    tipo: TipoDocumentoIa.guiaDocente,
  );
  if (doc == null) return null;
  try {
    return GuiaDocenteDto.fromJson(doc.contenido);
  } catch (_) {
    return null;
  }
});

final temarioProgressProvider =
    Provider.family<double, String>((ref, asignaturaId) {
  final guia = ref.watch(guiaDocenteDtoProvider(asignaturaId)).valueOrNull;
  return guia?.porcentajeTemario ?? 0;
});

class GuiaDocenteState {
  const GuiaDocenteState({
    this.analizando = false,
    this.guardando = false,
    this.error,
  });

  final bool analizando;
  final bool guardando;
  final String? error;
}

class GuiaDocenteNotifier extends StateNotifier<GuiaDocenteState> {
  GuiaDocenteNotifier(this.ref) : super(const GuiaDocenteState());

  final Ref ref;

  void _reiniciar() => state = const GuiaDocenteState();

  Future<GuiaDocenteDto?> extraerYGuardar({
    required String asignaturaId,
    required Uint8List pdfBytes,
    required String asignaturaNombre,
    String mimeType = 'application/pdf',
  }) async {
    state = const GuiaDocenteState(analizando: true);
    try {
      final service = ref.read(guiaDocenteIaServiceProvider);
      final dto = await service.extraerDesdePdf(pdfBytes, mimeType: mimeType);

      state = const GuiaDocenteState(guardando: true);
      final repo = ref.read(documentoIaRepositoryProvider);
      await repo.guardar(
        fuenteTipo: 'guia_docente',
        fuenteId: asignaturaId,
        asignaturaId: asignaturaId,
        fuenteTitulo: asignaturaNombre,
        tipo: TipoDocumentoIa.guiaDocente,
        contenido: dto.toJson(),
      );

      ref.invalidate(guiaDocenteDtoProvider(asignaturaId));
      _reiniciar();
      return dto;
    } on GuiaDocenteIaException catch (e) {
      state = GuiaDocenteState(error: e.message);
      return null;
    } catch (e) {
      state = GuiaDocenteState(error: 'Error inesperado: $e');
      return null;
    }
  }

  Future<void> toggleTema({
    required String asignaturaId,
    required int indice,
    required bool completado,
  }) async {
    final repo = ref.read(documentoIaRepositoryProvider);
    final doc = await repo.obtener(
      fuenteTipo: 'guia_docente',
      fuenteId: asignaturaId,
      tipo: TipoDocumentoIa.guiaDocente,
    );
    if (doc == null) return;
    try {
      final dto = GuiaDocenteDto.fromJson(doc.contenido);
      if (indice < 0 || indice >= dto.temario.length) return;
      final nuevos = List<TemaGuia>.from(dto.temario);
      nuevos[indice] = nuevos[indice].copyWith(completado: completado);
      await repo.guardar(
        fuenteTipo: 'guia_docente',
        fuenteId: asignaturaId,
        asignaturaId: asignaturaId,
        fuenteTitulo: '',
        tipo: TipoDocumentoIa.guiaDocente,
        contenido: dto.copyWith(temario: nuevos).toJson(),
      );
      ref.invalidate(guiaDocenteDtoProvider(asignaturaId));
    } catch (_) {}
  }

  Future<void> actualizarNota({
    required String asignaturaId,
    required int indice,
    required double? nota,
  }) async {
    final repo = ref.read(documentoIaRepositoryProvider);
    final doc = await repo.obtener(
      fuenteTipo: 'guia_docente',
      fuenteId: asignaturaId,
      tipo: TipoDocumentoIa.guiaDocente,
    );
    if (doc == null) return;
    try {
      final dto = GuiaDocenteDto.fromJson(doc.contenido);
      if (indice < 0 || indice >= dto.evaluacion.length) return;
      final nuevos = List<CriterioEvaluacion>.from(dto.evaluacion);
      nuevos[indice] = nuevos[indice].copyWith(notaObtenida: nota);
      await repo.guardar(
        fuenteTipo: 'guia_docente',
        fuenteId: asignaturaId,
        asignaturaId: asignaturaId,
        fuenteTitulo: '',
        tipo: TipoDocumentoIa.guiaDocente,
        contenido: dto.copyWith(evaluacion: nuevos).toJson(),
      );
      ref.invalidate(guiaDocenteDtoProvider(asignaturaId));
    } catch (_) {}
  }
}

final guiaDocenteStateProvider =
    StateNotifierProvider<GuiaDocenteNotifier, GuiaDocenteState>(
  (ref) => GuiaDocenteNotifier(ref),
);
