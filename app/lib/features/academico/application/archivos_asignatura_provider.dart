import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/archivo_asignatura_dto.dart';
import '../infrastructure/archivos_asignatura_repository.dart';

/// Repositorio de archivos de asignatura (subida R2 + metadatos Supabase).
final archivosRepositoryProvider = Provider<ArchivosAsignaturaRepository>(
  (ref) => ArchivosAsignaturaRepository(),
);

/// Archivos de una asignatura concreta (reactivo, más recientes primero).
final archivosAsignaturaProvider =
    FutureProvider.family<List<ArchivoAsignaturaDto>, String>(
  (ref, asignaturaId) async {
    final repo = ref.watch(archivosRepositoryProvider);
    return repo.listar(asignaturaId);
  },
);
