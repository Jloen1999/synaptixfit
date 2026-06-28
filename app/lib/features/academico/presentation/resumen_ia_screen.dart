import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/sv_colors.dart';
import '../../../core/design_system/sv_shapes.dart';
import '../application/documento_ia_provider.dart';
import '../application/estudio_ia_provider.dart';
import '../domain/fuente_estudio.dart';
import '../infrastructure/documento_ia_repository.dart';
import '../infrastructure/estudio_ia_service.dart';
import 'mapa_mental_screen.dart';

/// Pantalla que muestra un resumen del material generado por la IA (Clean UI).
class ResumenIaScreen extends ConsumerStatefulWidget {
  const ResumenIaScreen({required this.fuente, super.key});

  final FuenteEstudio fuente;

  @override
  ConsumerState<ResumenIaScreen> createState() => _ResumenIaScreenState();
}

class _ResumenIaScreenState extends ConsumerState<ResumenIaScreen> {
  bool _cargando = true;
  String? _error;
  String? _resumen;
  DateTime? _fecha;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  /// Carga el resumen guardado si existe; si no, lo genera y lo guarda.
  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final repo = ref.read(documentoIaRepositoryProvider);
      final guardado = await repo.obtener(
        fuenteTipo: widget.fuente.fuenteTipo,
        fuenteId: widget.fuente.fuenteId,
        tipo: TipoDocumentoIa.resumen,
      );
      if (!mounted) return;
      if (guardado != null && guardado.contenido.trim().isNotEmpty) {
        setState(() {
          _resumen = guardado.contenido;
          _fecha = guardado.actualizadoEn;
          _cargando = false;
        });
        return;
      }
    } catch (_) {
      // Si falla la lectura del documento, se genera igualmente.
    }
    if (!mounted) return;
    await _generarYGuardar();
  }

  /// Genera el resumen con la IA y lo persiste (sobrescribe el guardado).
  Future<void> _generarYGuardar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final servicio = ref.read(estudioIaServiceProvider);
      final resumen = await servicio.resumir(widget.fuente);

      try {
        await ref.read(documentoIaRepositoryProvider).guardar(
              fuenteTipo: widget.fuente.fuenteTipo,
              fuenteId: widget.fuente.fuenteId,
              asignaturaId: widget.fuente.asignaturaId,
              fuenteTitulo: widget.fuente.titulo,
              tipo: TipoDocumentoIa.resumen,
              contenido: resumen,
            );
        ref.invalidate(docsGuardadosProvider((
          fuenteTipo: widget.fuente.fuenteTipo,
          fuenteId: widget.fuente.fuenteId,
        )));
      } catch (_) {
        // Si el guardado falla, mostramos igualmente el resumen generado.
      }

      if (!mounted) return;
      setState(() {
        _resumen = resumen;
        _fecha = DateTime.now();
        _cargando = false;
      });
    } on EstudioIaException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo generar el resumen: $e';
        _cargando = false;
      });
    }
  }

  void _verMapaMental() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MapaMentalScreen(fuente: widget.fuente),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SVColors.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: SVColors.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: SVColors.onSurfaceVariant),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Volver',
        ),
        title: const Text(
          'Resumen con IA',
          style: TextStyle(
            color: SVColors.onSurfaceMuted,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: SVColors.onSurfaceVariant),
            tooltip: 'Regenerar',
            onPressed: _cargando ? null : _generarYGuardar,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(child: _buildCuerpo()),
      bottomNavigationBar: (_resumen != null && !_cargando)
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _verMapaMental,
                    style: FilledButton.styleFrom(
                      backgroundColor: SVColors.primary,
                      foregroundColor: SVColors.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: const RoundedRectangleBorder(
                          borderRadius: SVShapes.standard12),
                    ),
                    icon: const Icon(Icons.account_tree_outlined, size: 20),
                    label: const Text('Ver mapa mental',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildCuerpo() {
    if (_cargando) {
      return _Cargando(titulo: widget.fuente.titulo);
    }
    if (_error != null) {
      return _ErrorIa(mensaje: _error!, onReintentar: _generarYGuardar);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ChipIa(fecha: _fecha),
          const SizedBox(height: 12),
          Text(
            widget.fuente.titulo,
            style: const TextStyle(
              color: SVColors.onSurface,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: SVColors.outlineVariant),
          const SizedBox(height: 14),
          MarkdownBody(
            data: _resumen ?? '',
            selectable: true,
            styleSheet: _estiloMarkdown(context),
          ),
        ],
      ),
    );
  }

  MarkdownStyleSheet _estiloMarkdown(BuildContext context) {
    return MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
      p: const TextStyle(color: SVColors.onSurface, fontSize: 15, height: 1.7),
      h1: const TextStyle(
          color: SVColors.onSurface,
          fontSize: 21,
          fontWeight: FontWeight.w800,
          height: 1.3),
      h2: const TextStyle(
          color: SVColors.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          height: 1.3),
      h3: const TextStyle(
          color: SVColors.onSurface,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          height: 1.3),
      listBullet:
          const TextStyle(color: SVColors.onSurface, fontSize: 15, height: 1.7),
    );
  }
}

class _ChipIa extends StatelessWidget {
  const _ChipIa({this.fecha});

  final DateTime? fecha;

  @override
  Widget build(BuildContext context) {
    final sufijo = fecha != null ? ' · ${_relativa(fecha!)}' : '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: SVColors.primary.withValues(alpha: 0.10),
        borderRadius: SVShapes.pill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome, size: 14, color: SVColors.primary),
          const SizedBox(width: 6),
          Text('Resumen guardado$sufijo',
              style: const TextStyle(
                  color: SVColors.primary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  static String _relativa(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'ahora';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours} h';
    if (diff.inDays < 7) return 'hace ${diff.inDays} d';
    return '${d.day}/${d.month}/${d.year}';
  }
}

class _Cargando extends StatelessWidget {
  const _Cargando({required this.titulo});
  final String titulo;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            const SizedBox(height: 20),
            const Text('Generando resumen…',
                style: TextStyle(
                    color: SVColors.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
              titulo,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(color: SVColors.onSurfaceMuted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorIa extends StatelessWidget {
  const _ErrorIa({required this.mensaje, required this.onReintentar});
  final String mensaje;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome_outlined,
                size: 48, color: SVColors.onSurfaceMuted),
            const SizedBox(height: 12),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: SVColors.onSurfaceVariant, fontSize: 14),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: onReintentar,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
