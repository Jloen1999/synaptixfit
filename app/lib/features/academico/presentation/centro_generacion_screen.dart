import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/sv_colors.dart';
import '../../../core/design_system/sv_shapes.dart';
import '../application/apuntes_asignatura_provider.dart';
import '../application/apuntes_provider.dart';
import '../application/artefacto_efimero_provider.dart';
import '../domain/mapa_mental.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Pantalla unificada de generación con IA
// ──────────────────────────────────────────────────────────────────────────────

/// Pantalla que centraliza la previsualización de resúmenes y mapas mentales
/// generados por IA para una o varias fuentes de estudio.
///
/// Espera que [artefactoEfimeroProvider] esté sobrescrito con un notifier
/// que ya tenga las fuentes cargadas y el [TipoGeneracion] configurado.
/// Al iniciar, dispara automáticamente la generación si el estado es inactivo.
class CentroGeneracionScreen extends ConsumerStatefulWidget {
  const CentroGeneracionScreen({
    required this.tipo,
    required this.asignaturaId,
    this.color,
    super.key,
  });

  /// Tipo de generación a ejecutar.
  final TipoGeneracion tipo;

  /// Asignatura a la que pertenecen las fuentes (para guardar como apunte).
  final String asignaturaId;

  /// Color de acento de la asignatura (para el botón de guardar).
  final Color? color;

  @override
  ConsumerState<CentroGeneracionScreen> createState() =>
      _CentroGeneracionScreenState();
}

class _CentroGeneracionScreenState
    extends ConsumerState<CentroGeneracionScreen> {
  bool _inicioDisparado = false;

  @override
  void initState() {
    super.initState();
    _dispararGeneracion();
  }

  void _dispararGeneracion() {
    if (_inicioDisparado) return;

    // Leer el provider en el siguiente frame para evitar build durante init.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _inicioDisparado = true;

      try {
        final state = ref.read(artefactoEfimeroProvider);
        if (state.estado == EstadoGeneracion.inactivo) {
          _iniciarGeneracion(widget.tipo);
        }
      } catch (_) {
        if (mounted) Navigator.of(context).pop();
      }
    });
  }

  void _iniciarGeneracion(TipoGeneracion tipo) {
    final notifier = ref.read(artefactoEfimeroProvider.notifier);
    switch (tipo) {
      case TipoGeneracion.resumen:
        notifier.generarResumen();
      case TipoGeneracion.mapaMental:
        notifier.generarMapaMental();
      case TipoGeneracion.cuestionario:
        notifier.generarCuestionario();
    }
  }

  String get _tituloPantalla {
    final personalizado =
        ref.read(artefactoEfimeroProvider).tituloPersonalizado;
    return personalizado ??
        switch (widget.tipo) {
          TipoGeneracion.resumen => 'Resumen con IA',
          TipoGeneracion.mapaMental => 'Mapa mental',
          TipoGeneracion.cuestionario => 'Cuestionario',
        };
  }

  String get _tituloApunte {
    final state = ref.read(artefactoEfimeroProvider);
    return state.tituloEfectivo;
  }

  Future<void> _guardarComoApunte() async {
    final state = ref.read(artefactoEfimeroProvider);

    String contenido;
    switch (state.tipo) {
      case TipoGeneracion.resumen:
        contenido = state.contenido ?? '';
      case TipoGeneracion.mapaMental:
        if (state.mapa == null) return;
        contenido = _mapaToMarkdown(state.mapa!);
      case TipoGeneracion.cuestionario:
        // Cuestionario no se guarda como apunte en esta pantalla.
        return;
    }

    if (contenido.trim().isEmpty) return;

    try {
      await crearApunte(
        titulo: _tituloApunte,
        contenido: contenido,
        asignaturaId: widget.asignaturaId,
      );

      ref.invalidate(apuntesPorAsignaturaProvider(widget.asignaturaId));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Guardado como apunte — $_tituloApunte'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: SVColors.error,
        ),
      );
    }
  }

  String _mapaToMarkdown(MapaMental mapa) {
    final buf = StringBuffer();
    buf.writeln('# ${mapa.central}');
    buf.writeln();
    for (final rama in mapa.ramas) {
      buf.writeln('## ${rama.titulo}');
      _escribirNodo(buf, rama, '');
    }
    return buf.toString();
  }

  void _escribirNodo(StringBuffer buf, NodoMental nodo, String indent) {
    for (final hijo in nodo.hijos) {
      buf.writeln('$indent- ${hijo.titulo}');
      _escribirNodo(buf, hijo, '$indent  ');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(artefactoEfimeroProvider);

    return Scaffold(
      backgroundColor: SVColors.surfaceContainerLowest,
      appBar: _buildAppBar(),
      body: SafeArea(child: _buildCuerpo(state)),
      bottomNavigationBar: _buildBarraInferior(state),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: SVColors.surfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: SVColors.onSurfaceVariant),
        onPressed: () => Navigator.of(context).pop(),
        tooltip: 'Volver',
      ),
      title: Text(
        _tituloPantalla,
        style: const TextStyle(
          color: SVColors.onSurfaceMuted,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildCuerpo(ArtefactoEfimeroState state) {
    switch (state.estado) {
      case EstadoGeneracion.inactivo:
        return const SizedBox.shrink();

      case EstadoGeneracion.cargando:
        return _EstadoCargando(
          titulo: _tituloPantalla,
          onCancelar: () =>
              ref.read(artefactoEfimeroProvider.notifier).cancelar(),
        );

      case EstadoGeneracion.error:
        return _EstadoError(
          mensaje: state.error ?? 'Ocurrió un error inesperado.',
          onReintentar: () {
            ref.read(artefactoEfimeroProvider.notifier).regenerar();
          },
        );

      case EstadoGeneracion.completado:
        if (widget.tipo == TipoGeneracion.mapaMental) {
          if (state.mapa == null || state.mapa!.vacio) {
            return _EstadoError(
              mensaje: 'No se pudo generar el mapa mental.',
              onReintentar: () {
                ref.read(artefactoEfimeroProvider.notifier).regenerar();
              },
            );
          }
          return MapaMentalVista(mapa: state.mapa!);
        }

        // Resumen (y fallback para cuestionario)
        if (state.contenido == null || state.contenido!.trim().isEmpty) {
          return _EstadoError(
            mensaje: 'No se generó contenido.',
            onReintentar: () {
              ref.read(artefactoEfimeroProvider.notifier).regenerar();
            },
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: MarkdownBody(
            data: state.contenido!,
            selectable: true,
            styleSheet: _markdownStyleSheet(),
          ),
        );
    }
  }

  Widget _buildBarraInferior(ArtefactoEfimeroState state) {
    final completado = state.estado == EstadoGeneracion.completado;

    return Container(
      decoration: const BoxDecoration(
        color: SVColors.surfaceContainerLowest,
        border: Border(
          top: BorderSide(color: SVColors.outlineVariant, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              // 🔄 Regenerar
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 22),
                color: SVColors.onSurfaceVariant,
                tooltip: 'Regenerar',
                onPressed: () {
                  ref.read(artefactoEfimeroProvider.notifier).regenerar();
                },
              ),

              // 🗑️ Descartar
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 22),
                color: SVColors.onSurfaceVariant,
                tooltip: 'Descartar',
                onPressed: () => Navigator.of(context).pop(),
              ),

              const Spacer(),

              // 💾 Guardar como apunte
              FilledButton.icon(
                onPressed: completado ? _guardarComoApunte : null,
                icon: const Icon(Icons.save_outlined, size: 18),
                label: const Text('Guardar como apunte'),
                style: FilledButton.styleFrom(
                  backgroundColor: widget.color ?? SVColors.primary,
                  foregroundColor: SVColors.onPrimary,
                  disabledBackgroundColor: SVColors.surfaceContainerHighest,
                  disabledForegroundColor: SVColors.onSurfaceMuted,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(SVShapes.radiusStandard12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  MarkdownStyleSheet _markdownStyleSheet() {
    return MarkdownStyleSheet(
      h1: const TextStyle(
        color: SVColors.onSurface,
        fontSize: 24,
        fontWeight: FontWeight.w800,
        height: 1.3,
      ),
      h2: const TextStyle(
        color: SVColors.onSurface,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 1.3,
      ),
      h3: const TextStyle(
        color: SVColors.onSurface,
        fontSize: 17,
        fontWeight: FontWeight.w700,
        height: 1.3,
      ),
      p: const TextStyle(
        color: SVColors.onSurfaceVariant,
        fontSize: 15,
        height: 1.6,
      ),
      strong: const TextStyle(
        fontWeight: FontWeight.w800,
        color: SVColors.onSurface,
      ),
      listBullet: const TextStyle(
        color: SVColors.onSurfaceVariant,
        fontSize: 15,
      ),
      blockquoteDecoration: BoxDecoration(
        color: widget.color?.withValues(alpha: 0.08) ??
            SVColors.primary.withValues(alpha: 0.08),
        border: Border(
          left: BorderSide(
            color: widget.color ?? SVColors.primary,
            width: 3,
          ),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      code: const TextStyle(
        backgroundColor: SVColors.surfaceContainerHighest,
        color: SVColors.onSurfaceVariant,
        fontSize: 13,
      ),
      codeblockDecoration: BoxDecoration(
        color: SVColors.surfaceContainer,
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Estados: cargando y error
// ════════════════════════════════════════════════════════════════════════════

class _EstadoCargando extends StatelessWidget {
  const _EstadoCargando({required this.titulo, this.onCancelar});

  final String titulo;
  final VoidCallback? onCancelar;

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
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: SVColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Generando…',
              style: TextStyle(
                color: SVColors.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              titulo,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: SVColors.onSurfaceMuted,
                fontSize: 13,
              ),
            ),
            if (onCancelar != null) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: onCancelar,
                icon: const Icon(Icons.close, size: 18),
                label: const Text('Cancelar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: SVColors.error,
                  side: const BorderSide(color: SVColors.error),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EstadoError extends StatelessWidget {
  const _EstadoError({required this.mensaje, required this.onReintentar});

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
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: SVColors.onSurfaceMuted,
            ),
            const SizedBox(height: 12),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: SVColors.onSurfaceVariant,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: onReintentar,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Reintentar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: SVColors.primary,
                side: const BorderSide(color: SVColors.outlineVariant),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(SVShapes.radiusStandard12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Vista interactiva del mapa mental
// ════════════════════════════════════════════════════════════════════════════

const double _nodeW = 170.0;
const double _nodeH = 58.0;
const double _hGap = 64.0;
const double _vGap = 18.0;

const List<Color> _paleta = [
  Color(0xFF3B82F6),
  Color(0xFFEF4444),
  Color(0xFF10B981),
  Color(0xFFF59E0B),
  Color(0xFF8B5CF6),
  Color(0xFFEC4899),
  Color(0xFF14B8A6),
];

/// Widget público que muestra un [MapaMental] como un árbol interactivo de
/// nodos expandibles/colapsables, con zoom y desplazamiento.
class MapaMentalVista extends StatefulWidget {
  const MapaMentalVista({required this.mapa, super.key});

  final MapaMental mapa;

  @override
  State<MapaMentalVista> createState() => _MapaMentalVistaState();
}

class _MapaMentalVistaState extends State<MapaMentalVista> {
  final Set<String> _colapsados = {};
  final TransformationController _controller = TransformationController();
  bool _centrado = false;

  final Map<String, _NodoLayout> _nodos = {};
  final List<_Arista> _aristas = [];
  Size _lienzo = Size.zero;
  double _rowCursor = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _calcularLayout() {
    _nodos.clear();
    _aristas.clear();
    _rowCursor = 0;
    final root = NodoMental(
      id: 'root',
      titulo: widget.mapa.central,
      hijos: widget.mapa.ramas,
    );
    _layout(root, 0, SVColors.primary);

    double maxX = 0;
    double maxY = 0;
    for (final nl in _nodos.values) {
      maxX = math.max(maxX, nl.offset.dx + _nodeW);
      maxY = math.max(maxY, nl.offset.dy + _nodeH);
    }
    _lienzo = Size(maxX + 48, maxY + 48);
  }

  double _layout(NodoMental n, int depth, Color color) {
    final colapsado = _colapsados.contains(n.id);
    final hijos = colapsado ? const <NodoMental>[] : n.hijos;

    double y;
    if (hijos.isEmpty) {
      y = _rowCursor * (_nodeH + _vGap);
      _rowCursor += 1;
    } else {
      final ys = <double>[];
      for (var i = 0; i < hijos.length; i++) {
        final h = hijos[i];
        final colorHijo = depth == 0 ? _paleta[i % _paleta.length] : color;
        ys.add(_layout(h, depth + 1, colorHijo));
        _aristas.add(_Arista(padre: n.id, hijo: h.id, color: colorHijo));
      }
      y = (ys.first + ys.last) / 2;
    }

    _nodos[n.id] = _NodoLayout(
      id: n.id,
      titulo: n.titulo,
      offset: Offset(24 + depth * (_nodeW + _hGap), 24 + y),
      depth: depth,
      color: depth == 0 ? SVColors.primary : color,
      tieneHijos: n.tieneHijos,
      numHijos: n.hijos.length,
      colapsado: colapsado,
    );
    return y;
  }

  void _toggle(String id) {
    setState(() {
      if (_colapsados.contains(id)) {
        _colapsados.remove(id);
      } else {
        _colapsados.add(id);
      }
    });
  }

  void _centrarRaiz(double viewportH) {
    final root = _nodos['root'];
    if (root == null) return;
    final rootCenterY = root.offset.dy + _nodeH / 2;
    var ty = viewportH / 2 - rootCenterY;
    ty = math.min(ty, 24);
    _controller.value = Matrix4.identity()..setTranslationRaw(8.0, ty, 0.0);
  }

  @override
  Widget build(BuildContext context) {
    _calcularLayout();

    return LayoutBuilder(
      builder: (context, constraints) {
        if (!_centrado) {
          _centrado = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _centrarRaiz(constraints.maxHeight);
          });
        }
        return Stack(
          children: [
            InteractiveViewer(
              transformationController: _controller,
              constrained: false,
              minScale: 0.4,
              maxScale: 2.5,
              boundaryMargin: const EdgeInsets.all(280),
              child: SizedBox(
                width: math.max(_lienzo.width, constraints.maxWidth),
                height: math.max(_lienzo.height, constraints.maxHeight),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _AristasPainter(
                          nodos: Map.of(_nodos),
                          aristas: List.of(_aristas),
                        ),
                      ),
                    ),
                    for (final nl in _nodos.values)
                      Positioned(
                        left: nl.offset.dx,
                        top: nl.offset.dy,
                        child: _NodoCard(
                          layout: nl,
                          onTap: nl.tieneHijos ? () => _toggle(nl.id) : null,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const Positioned(
              left: 16,
              bottom: 12,
              child: _HintChip(),
            ),
            Positioned(
              right: 16,
              bottom: 12,
              child: _BotonReiniciar(
                onTap: () {
                  setState(() => _colapsados.clear());
                  _centrarRaiz(context.size?.height ?? 600);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Tipos internos del layout ─────────────────────────────────────────────────

class _NodoLayout {
  const _NodoLayout({
    required this.id,
    required this.titulo,
    required this.offset,
    required this.depth,
    required this.color,
    required this.tieneHijos,
    required this.numHijos,
    required this.colapsado,
  });

  final String id;
  final String titulo;
  final Offset offset;
  final int depth;
  final Color color;
  final bool tieneHijos;
  final int numHijos;
  final bool colapsado;
}

class _Arista {
  const _Arista({required this.padre, required this.hijo, required this.color});
  final String padre;
  final String hijo;
  final Color color;
}

// ── Pintor de aristas Bézier ──────────────────────────────────────────────────

class _AristasPainter extends CustomPainter {
  _AristasPainter({required this.nodos, required this.aristas});

  final Map<String, _NodoLayout> nodos;
  final List<_Arista> aristas;

  @override
  void paint(Canvas canvas, Size size) {
    for (final a in aristas) {
      final p = nodos[a.padre];
      final c = nodos[a.hijo];
      if (p == null || c == null) continue;

      final from = Offset(p.offset.dx + _nodeW, p.offset.dy + _nodeH / 2);
      final to = Offset(c.offset.dx, c.offset.dy + _nodeH / 2);
      final midX = (from.dx + to.dx) / 2;

      final path = Path()
        ..moveTo(from.dx, from.dy)
        ..cubicTo(midX, from.dy, midX, to.dy, to.dx, to.dy);

      final paint = Paint()
        ..color = a.color.withValues(alpha: 0.55)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_AristasPainter old) =>
      old.aristas.length != aristas.length || old.nodos.length != nodos.length;
}

// ── Tarjeta de nodo ───────────────────────────────────────────────────────────

class _NodoCard extends StatelessWidget {
  const _NodoCard({required this.layout, required this.onTap});

  final _NodoLayout layout;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final esRoot = layout.depth == 0;
    final color = layout.color;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: _nodeW,
        height: _nodeH,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: esRoot ? color : color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: esRoot
              ? null
              : Border.all(color: color.withValues(alpha: 0.6), width: 1.4),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                layout.titulo,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: esRoot ? SVColors.onPrimary : SVColors.onSurface,
                  fontSize: esRoot ? 13.5 : 12.5,
                  fontWeight: esRoot ? FontWeight.w800 : FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ),
            if (layout.tieneHijos) ...[
              const SizedBox(width: 8),
              _Insignia(
                texto: layout.colapsado ? '${layout.numHijos}' : '−',
                colapsado: layout.colapsado,
                color: esRoot ? SVColors.onPrimary : color,
                esRoot: esRoot,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Insignia de hijos (colapsable) ────────────────────────────────────────────

class _Insignia extends StatelessWidget {
  const _Insignia({
    required this.texto,
    required this.colapsado,
    required this.color,
    required this.esRoot,
  });

  final String texto;
  final bool colapsado;
  final Color color;
  final bool esRoot;

  @override
  Widget build(BuildContext context) {
    final fondo = colapsado
        ? color
        : (esRoot
            ? SVColors.onPrimary.withValues(alpha: 0.2)
            : color.withValues(alpha: 0.18));
    final textoColor =
        colapsado ? (esRoot ? color : SVColors.surfaceContainerLowest) : color;
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: fondo, shape: BoxShape.circle),
      child: Text(
        texto,
        style: TextStyle(
          color: textoColor,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
  }
}

// ── Chip de pista ─────────────────────────────────────────────────────────────

class _HintChip extends StatelessWidget {
  const _HintChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: SVColors.surfaceContainer.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.touch_app_outlined,
              size: 14, color: SVColors.onSurfaceMuted),
          SizedBox(width: 6),
          Text(
            'Toca un nodo para expandir · arrastra y pellizca',
            style: TextStyle(
              color: SVColors.onSurfaceMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Botón de reinicio de vista ────────────────────────────────────────────────

class _BotonReiniciar extends StatelessWidget {
  const _BotonReiniciar({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SVColors.surfaceContainerLowest,
      shape: const CircleBorder(),
      elevation: 2,
      shadowColor: SVColors.outlineVariant,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(10),
          child: Icon(
            Icons.center_focus_strong_outlined,
            size: 22,
            color: SVColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
