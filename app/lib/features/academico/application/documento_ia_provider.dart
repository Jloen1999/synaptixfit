import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../infrastructure/documento_ia_repository.dart';

/// Repositorio de documentos de IA (resúmenes y mapas mentales persistidos).
final documentoIaRepositoryProvider =
    Provider<DocumentoIaRepository>((ref) => DocumentoIaRepository());

/// Qué documentos de IA hay guardados para una fuente (para los badges del
/// sheet "Asistente de estudio"). La clave es un record `(fuenteTipo, fuenteId)`.
final docsGuardadosProvider = FutureProvider.family<DocsGuardados,
    ({String fuenteTipo, String fuenteId})>((ref, key) async {
  final repo = ref.read(documentoIaRepositoryProvider);
  return repo.existencias(fuenteTipo: key.fuenteTipo, fuenteId: key.fuenteId);
});
