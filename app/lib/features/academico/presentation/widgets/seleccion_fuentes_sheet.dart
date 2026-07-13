import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/sv_colors.dart';
import '../../../../core/design_system/sv_shapes.dart';
import '../../../../shared/models/db_models.dart';
import '../../application/apuntes_asignatura_provider.dart';
import '../../application/archivos_asignatura_provider.dart';
import '../../application/artefacto_efimero_provider.dart';
import '../../application/generacion_global_provider.dart';
import '../../domain/archivo_asignatura_dto.dart';
import '../../domain/fuente_estudio.dart';
import '../centro_generacion_screen.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Función pública de entrada
// ──────────────────────────────────────────────────────────────────────────────

/// Muestra un bottom sheet con las fuentes de estudio (apuntes y archivos) de
/// una asignatura, permitiendo seleccionar una o varias para generar un
/// resumen, mapa mental o cuestionario con IA.
///
/// Al presionar «Generar» se crea un [ArtefactoEfimeroNotifier], se cierra el
/// sheet y se navega a [CentroGeneracionScreen] con el provider sobrescrito.
Future<void> mostrarSeleccionFuentes(
  BuildContext context, {
  required WidgetRef ref,
  required String asignaturaId,
  required Color color,
  required TipoGeneracion tipoGeneracion,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: SVColors.surfaceContainerLowest,
    elevation: 0,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(SVShapes.radiusStandard12),
      ),
    ),
    builder: (sheetContext) => _SeleccionFuentesBody(
      asignaturaId: asignaturaId,
      color: color,
      tipoGeneracion: tipoGeneracion,
    ),
  );
}

// ──────────────────────────────────────────────────────────────────────────────
// Contenido del bottom sheet
// ──────────────────────────────────────────────────────────────────────────────

class _SeleccionFuentesBody extends ConsumerStatefulWidget {
  const _SeleccionFuentesBody({
    required this.asignaturaId,
    required this.color,
    required this.tipoGeneracion,
  });

  final String asignaturaId;
  final Color color;
  final TipoGeneracion tipoGeneracion;

  @override
  ConsumerState<_SeleccionFuentesBody> createState() =>
      _SeleccionFuentesBodyState();
}

class _SeleccionFuentesBodyState extends ConsumerState<_SeleccionFuentesBody> {
  /// IDs seleccionados, con prefijo para distinguir apuntes de archivos.
  final Set<String> _seleccionados = {};

  static const _prefijoApunte = 'apunte:';
  static const _prefijoArchivo = 'archivo:';

  String _claveApunte(String id) => '$_prefijoApunte$id';
  String _claveArchivo(String id) => '$_prefijoArchivo$id';

  bool _seleccionadoApunte(String id) =>
      _seleccionados.contains(_claveApunte(id));
  bool _seleccionadoArchivo(String id) =>
      _seleccionados.contains(_claveArchivo(id));

  void _toggleApunte(String id) {
    setState(() {
      final k = _claveApunte(id);
      if (_seleccionados.contains(k)) {
        _seleccionados.remove(k);
      } else {
        _seleccionados.add(k);
      }
    });
  }

  void _toggleArchivo(String id) {
    setState(() {
      final k = _claveArchivo(id);
      if (_seleccionados.contains(k)) {
        _seleccionados.remove(k);
      } else {
        _seleccionados.add(k);
      }
    });
  }

  void _generar() {
    final apuntesAsync =
        ref.read(apuntesPorAsignaturaProvider(widget.asignaturaId));
    final archivosAsync =
        ref.read(archivosAsignaturaProvider(widget.asignaturaId));

    final apuntes = apuntesAsync.valueOrNull ?? [];
    final archivos = archivosAsync.valueOrNull ?? [];

    final fuentes = <FuenteEstudio>[];

    for (final a in apuntes) {
      if (_seleccionadoApunte(a.id)) {
        fuentes.add(FuenteTexto(
          titulo: a.titulo,
          fuenteId: a.id,
          asignaturaId: widget.asignaturaId,
          contenido: a.contenido,
        ));
      }
    }

    for (final arch in archivos) {
      if (_seleccionadoArchivo(arch.id)) {
        fuentes.add(FuenteArchivo(
          titulo: arch.nombreArchivo,
          fuenteId: arch.id,
          asignaturaId: widget.asignaturaId,
          url: arch.urlPublica,
          mimeType: arch.tipoMime ?? 'application/octet-stream',
        ));
      }
    }

    if (fuentes.isEmpty) return;

    final notifier = ref.read(artefactoEfimeroProvider.notifier);
    notifier.limpiar();

    final tarea = ref.read(generacionGlobalProvider).registrar(
          titulo: fuentes.length == 1
              ? fuentes.first.titulo
              : '${fuentes.length} fuentes',
          tipo: widget.tipoGeneracion.name,
          onNavigate: () {},
        );

    notifier.iniciarYGenerar(fuentes, widget.tipoGeneracion,
        asignaturaId: widget.asignaturaId, tareaGlobalId: tarea.id);

    Navigator.of(context).pop();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CentroGeneracionScreen(
          tipo: widget.tipoGeneracion,
          asignaturaId: widget.asignaturaId,
          color: widget.color,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final apuntesAsync =
        ref.watch(apuntesPorAsignaturaProvider(widget.asignaturaId));
    final archivosAsync =
        ref.watch(archivosAsignaturaProvider(widget.asignaturaId));

    final apuntes = apuntesAsync.valueOrNull ?? [];
    final archivos = archivosAsync.valueOrNull ?? [];

    final maxHeight = MediaQuery.of(context).size.height * 0.8;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Cabecera ──────────────────────────────────────────────
          _buildHeader(),

          const Divider(
            height: 1,
            color: SVColors.outlineVariant,
          ),

          // ── Contenido desplazable ─────────────────────────────────
          Flexible(
            child: apuntesAsync.isLoading || archivosAsync.isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.only(bottom: 16),
                    shrinkWrap: true,
                    children: [
                      // ── Apuntes ───────────────────────────────────
                      if (apuntes.isNotEmpty) ...[
                        _buildSectionHeader('Apuntes', Icons.article_outlined),
                        ...apuntes.map((a) => _buildApunteTile(a)),
                      ],

                      // ── Archivos ──────────────────────────────────
                      if (archivos.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        _buildSectionHeader(
                            'Archivos', Icons.attach_file_outlined),
                        ...archivos.map((a) => _buildArchivoTile(a)),
                      ],

                      // ── Vacío ─────────────────────────────────────
                      if (apuntes.isEmpty && archivos.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 48),
                          child: Center(
                            child: Text(
                              'No hay apuntes ni archivos en esta asignatura.',
                              style: TextStyle(
                                color: SVColors.onSurfaceMuted,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),

          // ── Botón Generar ─────────────────────────────────────────
          _buildBotonGenerar(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 8, 12),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Seleccionar fuentes',
              style: TextStyle(
                color: SVColors.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: SVColors.onSurfaceVariant),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Cerrar',
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: widget.color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: widget.color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          const Spacer(),
          Text(
            '${_seleccionados.where((s) => s.startsWith(label == 'Apuntes' ? _prefijoApunte : _prefijoArchivo)).length} selec.',
            style: const TextStyle(
              color: SVColors.onSurfaceMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApunteTile(ApunteDb apunte) {
    final seleccionado = _seleccionadoApunte(apunte.id);

    return InkWell(
      onTap: () => _toggleApunte(apunte.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            Checkbox(
              value: seleccionado,
              onChanged: (_) => _toggleApunte(apunte.id),
              activeColor: widget.color,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      apunte.titulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: SVColors.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${apunte.contenido.length} caracteres',
                      style: const TextStyle(
                        color: SVColors.onSurfaceMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArchivoTile(ArchivoAsignaturaDto archivo) {
    final seleccionado = _seleccionadoArchivo(archivo.id);

    return InkWell(
      onTap: () => _toggleArchivo(archivo.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            Checkbox(
              value: seleccionado,
              onChanged: (_) => _toggleArchivo(archivo.id),
              activeColor: widget.color,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: archivo.tipo.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                archivo.tipo.icono,
                size: 18,
                color: archivo.tipo.color,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      archivo.nombreArchivo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: SVColors.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      archivo.tamanoLegible,
                      style: const TextStyle(
                        color: SVColors.onSurfaceMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBotonGenerar() {
    final habilitado = _seleccionados.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: const BoxDecoration(
        color: SVColors.surfaceContainerLowest,
        border: Border(
          top: BorderSide(color: SVColors.outlineVariant, width: 1),
        ),
      ),
      child: FilledButton(
        onPressed: habilitado ? _generar : null,
        style: FilledButton.styleFrom(
          backgroundColor: widget.color,
          foregroundColor: SVColors.onPrimary,
          disabledBackgroundColor: SVColors.surfaceContainerHighest,
          disabledForegroundColor: SVColors.onSurfaceMuted,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SVShapes.radiusStandard12),
          ),
        ),
        child: Text(
          habilitado ? 'Generar (${_seleccionados.length})' : 'Generar',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
