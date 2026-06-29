import 'package:supabase_flutter/supabase_flutter.dart';

/// Tipo de documento generado por la IA y persistido en `documentos_ia`.
enum TipoDocumentoIa { resumen, mapaMental, guiaDocente, practica }

extension TipoDocumentoIaX on TipoDocumentoIa {
  String get valorDb => switch (this) {
        TipoDocumentoIa.resumen => 'resumen',
        TipoDocumentoIa.mapaMental => 'mapa_mental',
        TipoDocumentoIa.guiaDocente => 'guia_docente',
        TipoDocumentoIa.practica => 'practica',
      };
}

/// Documento de IA guardado: Markdown (resumen) o JSON serializado (mapa).
class DocumentoIa {
  const DocumentoIa({
    required this.id,
    required this.contenido,
    required this.actualizadoEn,
  });

  final String id;
  final String contenido;
  final DateTime actualizadoEn;

  factory DocumentoIa.fromMap(Map<String, dynamic> m) => DocumentoIa(
        id: m['id'] as String,
        contenido: (m['contenido'] as String?) ?? '',
        actualizadoEn: DateTime.parse(m['actualizado_en'] as String),
      );
}

/// Qué documentos hay guardados para una fuente concreta.
typedef DocsGuardados = ({
  bool resumen,
  bool mapa,
  bool guiaDocente,
  bool practica
});

/// Acceso a `documentos_ia`: persiste y recupera los resúmenes y mapas mentales
/// generados por la IA. Un documento por (usuario, fuente, tipo) — el UPSERT
/// sobrescribe al regenerar.
class DocumentoIaRepository {
  SupabaseClient get _client => Supabase.instance.client;

  Future<DocumentoIa?> obtener({
    required String fuenteTipo,
    required String fuenteId,
    required TipoDocumentoIa tipo,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    final data = await _client
        .from('documentos_ia')
        .select()
        .eq('usuario_id', user.id)
        .eq('fuente_tipo', fuenteTipo)
        .eq('fuente_id', fuenteId)
        .eq('tipo', tipo.valorDb)
        .maybeSingle();
    if (data == null) return null;
    return DocumentoIa.fromMap(data);
  }

  Future<void> guardar({
    required String fuenteTipo,
    required String fuenteId,
    String? asignaturaId,
    required String fuenteTitulo,
    required TipoDocumentoIa tipo,
    required String contenido,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    await _client.from('documentos_ia').upsert({
      'usuario_id': user.id,
      'fuente_tipo': fuenteTipo,
      'fuente_id': fuenteId,
      'asignatura_id': asignaturaId,
      'fuente_titulo': fuenteTitulo,
      'tipo': tipo.valorDb,
      'contenido': contenido,
      'actualizado_en': DateTime.now().toIso8601String(),
    }, onConflict: 'usuario_id,fuente_tipo,fuente_id,tipo');
  }

  Future<DocumentoIa?> obtenerPorAsignatura(
    String asignaturaId,
    TipoDocumentoIa tipo,
  ) async {
    return obtener(
      fuenteTipo: tipo.valorDb,
      fuenteId: asignaturaId,
      tipo: tipo,
    );
  }

  Future<DocsGuardados> existencias({
    required String fuenteTipo,
    required String fuenteId,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null)
      return (resumen: false, mapa: false, guiaDocente: false, practica: false);
    final data = await _client
        .from('documentos_ia')
        .select('tipo')
        .eq('usuario_id', user.id)
        .eq('fuente_tipo', fuenteTipo)
        .eq('fuente_id', fuenteId);
    final tipos =
        (data as List).map((e) => (e as Map)['tipo'] as String).toSet();
    return (
      resumen: tipos.contains('resumen'),
      mapa: tipos.contains('mapa_mental'),
      guiaDocente: tipos.contains('guia_docente'),
      practica: tipos.contains('practica'),
    );
  }
}
