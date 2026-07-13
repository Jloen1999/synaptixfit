import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/fuente_estudio.dart';
import '../domain/mapa_mental.dart';
import '../infrastructure/documento_ia_repository.dart';
import 'documento_ia_provider.dart';
import 'estudio_ia_provider.dart';
import 'practica_provider.dart';

class BackgroundIaGenerator {
  final Map<String, Future<String>> _resumenesEnVuelo = {};
  final Map<String, Future<MapaMental>> _mapasEnVuelo = {};
  final Map<String, Future<List<Map<String, dynamic>>>> _practicasEnVuelo = {};
  final Map<String, String> _resumenesCache = {};
  final Map<String, MapaMental> _mapasCache = {};

  String _clave(FuenteEstudio f) => '${f.fuenteTipo}:${f.fuenteId}';

  bool tieneResumenEnVuelo(FuenteEstudio f) =>
      _resumenesEnVuelo.containsKey(_clave(f));
  bool tieneMapaEnVuelo(FuenteEstudio f) =>
      _mapasEnVuelo.containsKey(_clave(f));
  bool tienePracticaEnVuelo(FuenteEstudio f) =>
      _practicasEnVuelo.containsKey(_clave(f));

  void limpiarCacheResumen(FuenteEstudio f) {
    _resumenesCache.remove(_clave(f));
  }

  void limpiarCacheMapa(FuenteEstudio f) {
    _mapasCache.remove(_clave(f));
  }

  Future<String> generarResumen(FuenteEstudio fuente,
      {required WidgetRef ref}) async {
    final k = _clave(fuente);
    if (_resumenesCache.containsKey(k)) return _resumenesCache[k]!;
    if (_resumenesEnVuelo.containsKey(k)) return _resumenesEnVuelo[k]!;

    final futuro = _doGenerarResumen(fuente, ref);
    _resumenesEnVuelo[k] = futuro;
    try {
      final r = await futuro;
      _resumenesCache[k] = r;
      return r;
    } finally {
      _resumenesEnVuelo.remove(k);
    }
  }

  Future<String> _doGenerarResumen(FuenteEstudio fuente, WidgetRef ref) async {
    final docRepo = ref.read(documentoIaRepositoryProvider);
    try {
      final guardado = await docRepo.obtener(
        fuenteTipo: fuente.fuenteTipo,
        fuenteId: fuente.fuenteId,
        tipo: TipoDocumentoIa.resumen,
      );
      if (guardado != null && guardado.contenido.trim().isNotEmpty) {
        return guardado.contenido;
      }
    } catch (_) {}

    final ia = ref.read(estudioIaServiceProvider);
    final resumen = await ia.resumir(fuente);

    try {
      await docRepo.guardar(
        fuenteTipo: fuente.fuenteTipo,
        fuenteId: fuente.fuenteId,
        asignaturaId: fuente.asignaturaId,
        fuenteTitulo: fuente.titulo,
        tipo: TipoDocumentoIa.resumen,
        contenido: resumen,
      );
      ref.invalidate(docsGuardadosProvider((
        fuenteTipo: fuente.fuenteTipo,
        fuenteId: fuente.fuenteId,
      )));
    } catch (_) {}

    return resumen;
  }

  Future<MapaMental> generarMapa(FuenteEstudio fuente,
      {required WidgetRef ref}) async {
    final k = _clave(fuente);
    if (_mapasCache.containsKey(k)) return _mapasCache[k]!;
    if (_mapasEnVuelo.containsKey(k)) return _mapasEnVuelo[k]!;

    final futuro = _doGenerarMapa(fuente, ref);
    _mapasEnVuelo[k] = futuro;
    try {
      final r = await futuro;
      _mapasCache[k] = r;
      return r;
    } finally {
      _mapasEnVuelo.remove(k);
    }
  }

  Future<MapaMental> _doGenerarMapa(FuenteEstudio fuente, WidgetRef ref) async {
    final docRepo = ref.read(documentoIaRepositoryProvider);
    try {
      final guardado = await docRepo.obtener(
        fuenteTipo: fuente.fuenteTipo,
        fuenteId: fuente.fuenteId,
        tipo: TipoDocumentoIa.mapaMental,
      );
      if (guardado != null && guardado.contenido.trim().isNotEmpty) {
        try {
          final json = jsonDecode(guardado.contenido) as Map<String, dynamic>;
          final m = MapaMental.fromJson(json);
          if (!m.vacio) return m;
        } catch (_) {}
      }
    } catch (_) {}

    final ia = ref.read(estudioIaServiceProvider);
    final mapa = await ia.mapaMental(fuente);

    try {
      await docRepo.guardar(
        fuenteTipo: fuente.fuenteTipo,
        fuenteId: fuente.fuenteId,
        asignaturaId: fuente.asignaturaId,
        fuenteTitulo: fuente.titulo,
        tipo: TipoDocumentoIa.mapaMental,
        contenido: jsonEncode(mapa.toJson()),
      );
      ref.invalidate(docsGuardadosProvider((
        fuenteTipo: fuente.fuenteTipo,
        fuenteId: fuente.fuenteId,
      )));
    } catch (_) {}

    return mapa;
  }

  Future<List<Map<String, dynamic>>> generarPractica(FuenteEstudio fuente,
      {required WidgetRef ref}) async {
    final k = _clave(fuente);
    if (_practicasEnVuelo.containsKey(k)) return _practicasEnVuelo[k]!;

    final futuro = _doGenerarPractica(fuente, ref);
    _practicasEnVuelo[k] = futuro;
    try {
      return await futuro;
    } finally {
      _practicasEnVuelo.remove(k);
    }
  }

  Future<List<Map<String, dynamic>>> _doGenerarPractica(
      FuenteEstudio fuente, WidgetRef ref) async {
    final ia = ref.read(estudioIaServiceProvider);
    final preguntas = await ia.generarPractica(fuente);

    final repo = ref.read(practicaRepositoryProvider);
    final tipoFuente = fuente is FuenteTexto ? 'apunte' : 'archivo';
    final banco = await repo.obtenerOCrearBancoPorFuente(
      tipoOrigen: tipoFuente,
      origenId: fuente.fuenteId,
      asignaturaId: fuente.asignaturaId,
      titulo: fuente.titulo,
    );
    await repo.guardarPreguntas(banco.id, preguntas);

    try {
      await ref.read(documentoIaRepositoryProvider).guardar(
            fuenteTipo: tipoFuente,
            fuenteId: fuente.fuenteId,
            asignaturaId: fuente.asignaturaId,
            fuenteTitulo: fuente.titulo,
            tipo: TipoDocumentoIa.practica,
            contenido: '',
          );
      ref.invalidate(docsGuardadosProvider((
        fuenteTipo: tipoFuente,
        fuenteId: fuente.fuenteId,
      )));
    } catch (_) {}

    return preguntas;
  }
}

final backgroundIaGeneratorProvider =
    Provider<BackgroundIaGenerator>((ref) => BackgroundIaGenerator());
