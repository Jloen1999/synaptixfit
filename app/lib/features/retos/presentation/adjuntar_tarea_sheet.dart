import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/design_system/sv_colors.dart';
import '../../../core/design_system/sv_shapes.dart';
import '../../academico/application/archivos_asignatura_provider.dart';
import '../../academico/domain/archivo_asignatura_dto.dart';
import '../../academico/infrastructure/archivos_asignatura_repository.dart';

/// Adjunto académico elegido para una tarea de reto (apunte o archivo).
/// Solo uno de los dos ids estará presente.
class AdjuntoTarea {
  const AdjuntoTarea({this.apunteId, this.archivoId, required this.titulo})
      : assert(apunteId != null || archivoId != null);

  final String? apunteId;
  final String? archivoId;
  final String titulo;
}

/// Abre el selector de adjuntos para una tarea de reto.
///
/// Permite adjuntar un apunte o archivo ya subidos, o subir un archivo nuevo
/// que queda registrado en `archivos_asignatura` (visible en Académico) y
/// vinculado a la asignatura efectiva de la tarea.
Future<AdjuntoTarea?> mostrarAdjuntarTareaSheet(
  BuildContext context, {
  String? asignaturaId,
}) {
  return showModalBottomSheet<AdjuntoTarea?>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: SVColors.surfaceContainerLowest,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => AdjuntarTareaSheet(asignaturaId: asignaturaId),
  );
}

class AdjuntarTareaSheet extends ConsumerStatefulWidget {
  const AdjuntarTareaSheet({required this.asignaturaId, super.key});

  /// Asignatura efectiva de la tarea (para vincular archivos nuevos).
  final String? asignaturaId;

  @override
  ConsumerState<AdjuntarTareaSheet> createState() => _AdjuntarTareaSheetState();
}

class _AdjuntarTareaSheetState extends ConsumerState<AdjuntarTareaSheet> {
  String _pestana = 'apuntes'; // 'apuntes' | 'archivos'
  bool _cargando = true;
  bool _subiendo = false;
  double _progreso = 0;
  List<_ApunteFila> _apuntes = [];
  List<_ArchivoFila> _archivos = [];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _cargando = false);
      return;
    }

    var apuntes = <_ApunteFila>[];
    var archivos = <_ArchivoFila>[];
    try {
      final apuntesData = await client
          .from('apuntes')
          .select('id, titulo, asignaturas(nombre)')
          .eq('usuario_id', user.id)
          .order('actualizado_en', ascending: false)
          .limit(50);
      apuntes = (apuntesData as List)
          .map((e) => _ApunteFila(
                id: e['id'] as String,
                titulo: e['titulo'] as String? ?? 'Sin título',
                asignaturaNombre: _nombreAsignatura(e['asignaturas']),
              ))
          .toList();
    } catch (_) {
      apuntes = [];
    }
    try {
      final archivosData = await client
          .from('archivos_asignatura')
          .select('id, nombre_archivo, asignaturas(nombre)')
          .eq('usuario_id', user.id)
          .order('creado_en', ascending: false)
          .limit(50);
      archivos = (archivosData as List)
          .map((e) => _ArchivoFila(
                id: e['id'] as String,
                nombre: e['nombre_archivo'] as String,
                asignaturaNombre: _nombreAsignatura(e['asignaturas']),
              ))
          .toList();
    } catch (_) {
      archivos = [];
    }

    if (!mounted) return;
    setState(() {
      _apuntes = apuntes;
      _archivos = archivos;
      _cargando = false;
    });
  }

  static String? _nombreAsignatura(dynamic raw) =>
      raw is Map ? raw['nombre'] as String? : null;

  Future<void> _subirArchivo() async {
    if (_subiendo) return;
    if (widget.asignaturaId == null) {
      _aviso('Elige primero una asignatura en el reto para subir archivos.');
      return;
    }

    final FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(withData: true);
    } catch (_) {
      _aviso('No se pudo abrir el selector de archivos.');
      return;
    }
    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      _aviso('No se pudo leer el archivo seleccionado.');
      return;
    }

    setState(() {
      _subiendo = true;
      _progreso = 0;
    });
    try {
      final repo = ref.read(archivosRepositoryProvider);
      final dto = await repo.subirArchivo(
        asignaturaId: widget.asignaturaId!,
        nombreArchivo: file.name,
        bytes: bytes,
        onProgreso: (p) {
          if (mounted) setState(() => _progreso = p);
        },
      );
      // El archivo queda registrado en `archivos_asignatura`: invalidamos para
      // que aparezca en la pestaña Archivos de Académico.
      ref.invalidate(archivosAsignaturaProvider(widget.asignaturaId!));
      if (!mounted) return;
      Navigator.pop(
        context,
        AdjuntoTarea(archivoId: dto.id, titulo: dto.nombreArchivo),
      );
    } on ArchivoStorageException catch (e) {
      if (!mounted) return;
      setState(() => _subiendo = false);
      _aviso(e.mensaje);
    } catch (e) {
      if (!mounted) return;
      setState(() => _subiendo = false);
      _aviso('No se pudo subir el archivo: $e');
    }
  }

  void _aviso(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.78,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: SVColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text('Adjuntar a la tarea',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: SVColors.onSurface)),
            ),
            const SizedBox(height: 12),
            // Pestañas planas: Apuntes / Archivos
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _Pestana(
                    icon: Icons.description_outlined,
                    label: 'Apuntes',
                    sel: _pestana == 'apuntes',
                    onTap: () => setState(() => _pestana = 'apuntes'),
                  ),
                  const SizedBox(width: 8),
                  _Pestana(
                    icon: Icons.attach_file_rounded,
                    label: 'Archivos',
                    sel: _pestana == 'archivos',
                    onTap: () => setState(() => _pestana = 'archivos'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            if (_pestana == 'archivos')
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 2),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _subiendo ? null : _subirArchivo,
                    icon: _subiendo
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, value: _progreso),
                          )
                        : const Icon(Icons.cloud_upload_outlined, size: 18),
                    label:
                        Text(_subiendo ? 'Subiendo…' : 'Subir archivo nuevo'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: SVColors.secondary,
                      side: BorderSide(
                          color: SVColors.secondary.withValues(alpha: 0.4)),
                      minimumSize: const Size.fromHeight(44),
                      shape: const RoundedRectangleBorder(
                          borderRadius: SVShapes.standard12),
                    ),
                  ),
                ),
              ),
            Flexible(
              child: _cargando
                  ? const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _pestana == 'apuntes'
                      ? _buildApuntes()
                      : _buildArchivos(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApuntes() {
    if (_apuntes.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text('No tienes apuntes todavía. Crea uno en Académico.',
              textAlign: TextAlign.center,
              style: TextStyle(color: SVColors.onSurfaceMuted, fontSize: 13)),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _apuntes.length,
      itemBuilder: (context, i) {
        final a = _apuntes[i];
        return _FilaAdjunto(
          icon: Icons.description_outlined,
          color: const Color(0xFF3B82F6),
          titulo: a.titulo,
          subtitulo: a.asignaturaNombre,
          onTap: () => Navigator.pop(
              context, AdjuntoTarea(apunteId: a.id, titulo: a.titulo)),
        );
      },
    );
  }

  Widget _buildArchivos() {
    if (_archivos.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text(
              'No tienes archivos todavía. Súbelos desde aquí o en Académico.',
              textAlign: TextAlign.center,
              style: TextStyle(color: SVColors.onSurfaceMuted, fontSize: 13)),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _archivos.length,
      itemBuilder: (context, i) {
        final a = _archivos[i];
        final tipo = TipoArchivo.desdeNombre(a.nombre);
        return _FilaAdjunto(
          icon: tipo.icono,
          color: tipo.color,
          titulo: a.nombre,
          subtitulo: a.asignaturaNombre,
          onTap: () => Navigator.pop(
              context, AdjuntoTarea(archivoId: a.id, titulo: a.nombre)),
        );
      },
    );
  }
}

class _ApunteFila {
  const _ApunteFila({
    required this.id,
    required this.titulo,
    this.asignaturaNombre,
  });

  final String id;
  final String titulo;
  final String? asignaturaNombre;
}

class _ArchivoFila {
  const _ArchivoFila({
    required this.id,
    required this.nombre,
    this.asignaturaNombre,
  });

  final String id;
  final String nombre;
  final String? asignaturaNombre;
}

class _Pestana extends StatelessWidget {
  const _Pestana({
    required this.icon,
    required this.label,
    required this.sel,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool sel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = sel ? SVColors.secondary : SVColors.onSurfaceMuted;
    return Expanded(
      child: Material(
        color: sel
            ? SVColors.secondary.withValues(alpha: 0.1)
            : SVColors.surfaceContainerLow,
        borderRadius: SVShapes.pill,
        child: InkWell(
          onTap: onTap,
          borderRadius: SVShapes.pill,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: fg),
                const SizedBox(width: 6),
                Text(label,
                    style: TextStyle(
                        color: fg, fontSize: 13, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FilaAdjunto extends StatelessWidget {
  const _FilaAdjunto({
    required this.icon,
    required this.color,
    required this.titulo,
    required this.subtitulo,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String titulo;
  final String? subtitulo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: SVShapes.standard,
        ),
        child: Icon(icon, size: 18, color: color),
      ),
      title: Text(titulo,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: SVColors.onSurface)),
      subtitle: subtitulo == null
          ? null
          : Text(subtitulo!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 11, color: SVColors.onSurfaceMuted)),
      onTap: onTap,
    );
  }
}
