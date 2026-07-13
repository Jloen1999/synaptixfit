import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/design_system/sv_colors.dart';
import '../../../core/design_system/sv_shapes.dart';
import '../../../shared/models/db_models.dart';
import '../application/apuntes_asignatura_provider.dart';
import '../application/apuntes_provider.dart';
import '../application/archivos_asignatura_provider.dart';
import '../application/asignaturas_provider.dart';
import '../application/conteos_asignatura_provider.dart';
import '../application/documento_ia_provider.dart';
import '../application/generacion_global_provider.dart';

import '../application/materiales_estudio_provider.dart';
import '../application/multi_tema_provider.dart';
import '../application/practica_provider.dart';
import '../application/tareas_asignatura_provider.dart';
import '../domain/archivo_asignatura_dto.dart';
import '../domain/asignatura_visual.dart';
import '../domain/fuente_estudio.dart';
import '../infrastructure/estudio_ia_service.dart';
import '../application/artefacto_efimero_provider.dart';
import 'apunte_visor_screen.dart';
import 'centro_generacion_screen.dart';
import 'cuestionario_formato_screen.dart';
import 'mapa_mental_screen.dart';
import 'resumen_ia_screen.dart';
import 'widgets/archivo_tile.dart';
import 'widgets/dashboard_asignatura_tab.dart';
import 'widgets/tareas_asignatura_tab.dart';
import 'widgets/seleccion_fuentes_sheet.dart';

// ══════════════════════════════════════════════════════════════════════════════
// AsignaturaDetalleScreen
// ══════════════════════════════════════════════════════════════════════════════

class AsignaturaDetalleScreen extends ConsumerStatefulWidget {
  const AsignaturaDetalleScreen({
    required this.asignaturaId,
    this.asignaturaInicial,
    super.key,
  });

  final String asignaturaId;
  final AsignaturaDb? asignaturaInicial;

  @override
  ConsumerState<AsignaturaDetalleScreen> createState() =>
      _AsignaturaDetalleScreenState();
}

class _AsignaturaDetalleScreenState
    extends ConsumerState<AsignaturaDetalleScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsignaturaDb? asignatura;
    if (widget.asignaturaInicial != null) {
      asignatura = widget.asignaturaInicial;
    } else {
      asignatura =
          ref.watch(asignaturaPorIdProvider(widget.asignaturaId)).valueOrNull;
    }

    final color = colorAsignatura(widget.asignaturaId);
    final siglas = asignatura != null ? siglasAsignatura(asignatura) : '···';
    final nombre = asignatura?.nombre ?? 'Asignatura';
    final conteos =
        ref.watch(conteosAsignaturaProvider(widget.asignaturaId)).valueOrNull;
    final tareas =
        ref.watch(tareasAsignaturaProvider(widget.asignaturaId)).valueOrNull;
    int? pendientesHoy;
    if (tareas != null) {
      final ahora = DateTime.now();
      final hoy = DateTime(ahora.year, ahora.month, ahora.day);
      pendientesHoy = tareas.where((t) {
        final r = t.referenciaTemporal;
        return !t.completado && DateTime(r.year, r.month, r.day) == hoy;
      }).length;
    }

    return Scaffold(
      backgroundColor: SVColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(
              siglas: siglas,
              nombre: nombre,
              color: color,
              apuntes: conteos?.apuntes,
              archivos: conteos?.archivos,
              pendientesHoy: pendientesHoy,
              ref: ref,
              asignaturaId: widget.asignaturaId,
            ),
            _FlatTabBar(controller: _tab, color: color),
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  _ProgresoTab(
                    asignaturaId: widget.asignaturaId,
                    asignaturaNombre: nombre,
                    color: color,
                  ),
                  _TemarioTab(
                    asignaturaId: widget.asignaturaId,
                    color: color,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.siglas,
    required this.nombre,
    required this.color,
    this.apuntes,
    this.archivos,
    this.pendientesHoy,
    required this.ref,
    required this.asignaturaId,
  });

  final String siglas;
  final String nombre;
  final Color color;
  final int? apuntes;
  final int? archivos;
  final int? pendientesHoy;
  final WidgetRef ref;
  final String asignaturaId;

  String _metricas() {
    final partes = <String>[
      '$apuntes ${apuntes == 1 ? 'apunte' : 'apuntes'}',
      '$archivos ${archivos == 1 ? 'archivo' : 'archivos'}',
    ];
    if (pendientesHoy != null) {
      partes.add(
          '$pendientesHoy ${pendientesHoy == 1 ? 'pendiente' : 'pendientes'} hoy');
    }
    return partes.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 8, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back,
                    color: SVColors.onSurfaceVariant),
                tooltip: 'Volver',
              ),
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: SVShapes.standard12,
                ),
                child: Text(
                  siglas,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      nombre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: SVColors.onSurface,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    if (apuntes != null && archivos != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        _metricas(),
                        style: const TextStyle(
                          color: SVColors.onSurfaceMuted,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Row(
              children: [
                _BotonGeneracion(
                  onTap: () => _generarGlobal(context, TipoGeneracion.resumen),
                  color: color,
                  child: const Text('Resumen',
                      style: TextStyle(
                          fontSize: 11.5, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 8),
                _BotonGeneracion(
                  onTap: () =>
                      _generarGlobal(context, TipoGeneracion.mapaMental),
                  color: color,
                  child: const Text('Mapa mental',
                      style: TextStyle(
                          fontSize: 11.5, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 8),
                _BotonGeneracion(
                  onTap: () =>
                      _generarGlobal(context, TipoGeneracion.cuestionario),
                  color: color,
                  child: const Text('Cuestionario',
                      style: TextStyle(
                          fontSize: 11.5, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _generarGlobal(BuildContext context, TipoGeneracion tipo) {
    mostrarSeleccionFuentes(
      context,
      ref: ref,
      asignaturaId: asignaturaId,
      color: color,
      tipoGeneracion: tipo,
    );
  }
}

class _BotonGeneracion extends StatelessWidget {
  const _BotonGeneracion({
    required this.onTap,
    required this.color,
    required this.child,
  });

  final VoidCallback onTap;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: SVShapes.standard12,
        ),
        child: DefaultTextStyle(
          style: TextStyle(color: color),
          child: child,
        ),
      ),
    );
  }
}

// ── TabBar ────────────────────────────────────────────────────────────────────

class _FlatTabBar extends StatelessWidget {
  const _FlatTabBar({required this.controller, required this.color});

  final TabController controller;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(
        color: SVColors.surfaceContainerLow,
        borderRadius: SVShapes.standard12,
      ),
      // El indicador se dirige por `controller.animation` (continuo durante el
      // swipe) en lugar de `controller.index` (discreto, que se actualizaba al
      // asentarse la página y provocaba el lag del foco al deslizar).
      child: AnimatedBuilder(
        animation: controller.animation ?? controller,
        builder: (context, _) {
          final t = controller.animation?.value ?? controller.index.toDouble();
          return Row(
            children: [
              _celda(0, Icons.trending_up_rounded, 'Progreso', t),
              _celda(1, Icons.menu_book_rounded, 'Temario', t),
            ],
          );
        },
      ),
    );
  }

  Widget _celda(int index, IconData icono, String texto, double t) {
    // 1.0 = totalmente seleccionada; 0.0 = inactiva. Interpola con el swipe.
    final sel = (1.0 - (t - index).abs()).clamp(0.0, 1.0);
    final contenido =
        Color.lerp(SVColors.onSurfaceVariant, color, sel) ?? color;
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.animateTo(index),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14 * sel),
            borderRadius: SVShapes.standard,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icono, size: 16, color: contenido),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  texto,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: contenido,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Pestaña fusionada: Progreso (Dashboard + Tareas)
// ══════════════════════════════════════════════════════════════════════════════

class _ProgresoTab extends ConsumerWidget {
  const _ProgresoTab({
    required this.asignaturaId,
    required this.asignaturaNombre,
    required this.color,
  });

  final String asignaturaId;
  final String asignaturaNombre;
  final Color color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 1,
          child: DashboardAsignaturaTab(
            asignaturaId: asignaturaId,
            asignaturaNombre: asignaturaNombre,
            color: color,
          ),
        ),
        Expanded(
          flex: 2,
          child: TareasAsignaturaTab(asignaturaId: asignaturaId, color: color),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Pestaña fusionada: Temario (Apuntes + Archivos)
// ══════════════════════════════════════════════════════════════════════════════

class _TemarioTab extends ConsumerStatefulWidget {
  const _TemarioTab({required this.asignaturaId, required this.color});

  final String asignaturaId;
  final Color color;

  @override
  ConsumerState<_TemarioTab> createState() => _TemarioTabState();
}

class _TemarioTabState extends ConsumerState<_TemarioTab> {
  final _scrollCtrl = ScrollController();

  Future<void> _crearApunte() async {
    final guardado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => EditorApunteScreen(
          asignaturaId: widget.asignaturaId,
          existente: null,
        ),
      ),
    );
    if (guardado == true) {
      ref.invalidate(apuntesPorAsignaturaProvider(widget.asignaturaId));
      ref.invalidate(conteosAsignaturaProvider(widget.asignaturaId));
      ref.invalidate(apuntesProvider);
    }
  }

  Future<void> _abrirVisor(ApunteDb apunte) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ApunteVisorScreen(apunte: apunte),
      ),
    );
    ref.invalidate(apuntesPorAsignaturaProvider(widget.asignaturaId));
    ref.invalidate(conteosAsignaturaProvider(widget.asignaturaId));
    ref.invalidate(apuntesProvider);
  }

  Future<String?> _obtenerMaterialId(ApunteDb apunte) async {
    try {
      final result = await Supabase.instance.client
          .from('materiales_estudio')
          .select('id')
          .eq('tipo_origen', 'apunte')
          .eq('origen_id', apunte.id)
          .maybeSingle();
      return result?['id'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _obtenerMaterialIdArchivo(ArchivoAsignaturaDto a) async {
    try {
      final result = await Supabase.instance.client
          .from('materiales_estudio')
          .select('id')
          .eq('tipo_origen', 'archivo')
          .eq('origen_id', a.id)
          .maybeSingle();
      return result?['id'] as String?;
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final apuntesAsync =
        ref.watch(apuntesPorAsignaturaProvider(widget.asignaturaId));
    final archivosAsync =
        ref.watch(archivosAsignaturaProvider(widget.asignaturaId));
    final modoSeleccion = ref.watch(modoSeleccionActivoProvider);
    final seleccionados = ref.watch(seleccionMaterialesProvider);
    final itemsSeleccionados = ref.watch(seleccionItemsProvider);

    return Stack(
      children: [
        ListView(
          controller: _scrollCtrl,
          padding: EdgeInsets.fromLTRB(16, 4, 16,
              modoSeleccion && itemsSeleccionados.isNotEmpty ? 140 : 90),
          children: [
            Row(children: [
              Expanded(
                child: _SeccionTitulo(
                    icono: Icons.notes_rounded,
                    texto: modoSeleccion
                        ? 'Apuntes (${_contarApuntes(itemsSeleccionados, apuntesAsync)})'
                        : 'Apuntes',
                    color: widget.color),
              ),
              if (modoSeleccion)
                GestureDetector(
                  onTap: () => _seleccionarTodosApuntes(ref, apuntesAsync),
                  child: Text(
                    _todosSeleccionadosApuntes(itemsSeleccionados, apuntesAsync)
                        ? 'Deseleccionar todos'
                        : 'Seleccionar todos',
                    style: TextStyle(
                        color: widget.color,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              const SizedBox(width: 4),
              TextButton.icon(
                onPressed: () {
                  ref.read(modoSeleccionActivoProvider.notifier).state =
                      !modoSeleccion;
                  if (modoSeleccion) {
                    ref.read(seleccionMaterialesProvider.notifier).state = {};
                    ref.read(seleccionItemsProvider.notifier).state = {};
                  }
                },
                icon: Icon(
                    modoSeleccion ? Icons.close : Icons.checklist_outlined,
                    size: 18),
                label: Text(modoSeleccion ? 'Cancelar' : 'Seleccionar',
                    style: const TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  foregroundColor: widget.color,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ]),
            const SizedBox(height: 6),
            apuntesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _vacio(Icons.error_outline,
                  'No se pudieron cargar los apuntes', '$e'),
              data: (apuntes) {
                if (apuntes.isEmpty) {
                  return _vacio(Icons.notes_rounded, 'Sin apuntes todavía',
                      'Pulsa + para crear tu primera nota.');
                }
                return Column(
                  children: apuntes
                      .map((a) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _ApunteRow(
                              apunte: a,
                              onTap: () {
                                if (modoSeleccion) {
                                  _toggleSeleccionMaterial(a.id, ref, a);
                                } else {
                                  _abrirVisor(a);
                                }
                              },
                              onLongPress: () =>
                                  _entrarModoSeleccion(ref, a.id, a),
                              modoSeleccion: modoSeleccion,
                              seleccionado: itemsSeleccionados.contains(a.id),
                              onToggleSeleccion: () {
                                _toggleSeleccionMaterial(a.id, ref, a);
                              },
                            ),
                          ))
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 20),
            _SeccionTitulo(
                icono: Icons.folder_outlined,
                texto: modoSeleccion
                    ? 'Archivos (${_contarArchivos(itemsSeleccionados, archivosAsync)})'
                    : 'Archivos',
                color: widget.color),
            if (modoSeleccion)
              GestureDetector(
                onTap: () => _seleccionarTodosArchivos(ref, archivosAsync),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    _todosSeleccionadosArchivos(
                            itemsSeleccionados, archivosAsync)
                        ? 'Deseleccionar todos'
                        : 'Seleccionar todos',
                    style: TextStyle(
                        color: widget.color,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _subirArchivo,
                style: OutlinedButton.styleFrom(
                  foregroundColor: widget.color,
                  side: BorderSide(color: widget.color.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: const RoundedRectangleBorder(
                      borderRadius: SVShapes.standard12),
                ),
                icon: const Icon(Icons.upload_file_outlined, size: 20),
                label: const Text('Subir archivo',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 8),
            archivosAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _vacio(Icons.error_outline,
                  'No se pudieron cargar los archivos', '$e'),
              data: (archivos) {
                if (archivos.isEmpty) {
                  return _vacio(
                    Icons.folder_outlined,
                    'Sin archivos todavía',
                    'Sube PDFs, imágenes o documentos para generar resúmenes y tests.',
                  );
                }
                return Column(
                  children: archivos
                      .map((a) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: ArchivoTile(
                              archivo: a,
                              onAbrir: () {
                                if (modoSeleccion) {
                                  _toggleSeleccionMaterialArchivo(a.id, ref, a);
                                } else {
                                  context.push('/academico/archivo/visor',
                                      extra: a);
                                }
                              },
                              onLongPress: () =>
                                  _entrarModoSeleccionArchivo(ref, a.id, a),
                              onEliminar: () => _eliminarArchivo(a),
                              modoSeleccion: modoSeleccion,
                              seleccionado: itemsSeleccionados.contains(a.id),
                              onToggleSeleccion: () {
                                _toggleSeleccionMaterialArchivo(a.id, ref, a);
                              },
                            ),
                          ))
                      .toList(),
                );
              },
            ),
          ],
        ),
        if (modoSeleccion && itemsSeleccionados.isNotEmpty)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BarraAccionesSeleccion(
              seleccionadosCount: itemsSeleccionados.length,
              onEliminar: () => _eliminarSeleccionados(context, ref),
              onCuestionario: seleccionados.length >= 2
                  ? () => _generarCuestionarioCombinado(context, ref)
                  : null,
              color: widget.color,
              onCancelar: () {
                ref.read(modoSeleccionActivoProvider.notifier).state = false;
                ref.read(seleccionItemsProvider.notifier).state = {};
                ref.read(seleccionMaterialesProvider.notifier).state = {};
              },
            ),
          )
        else
          Positioned(
            right: 20,
            bottom: 20,
            child: FloatingActionButton(
              backgroundColor: widget.color,
              foregroundColor: SVColors.onPrimary,
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              onPressed: _crearApunte,
              child: const Icon(Icons.add),
            ),
          ),
      ],
    );
  }

  // TODO(Fase2): mostrar barra de progreso durante la subida

  void _toggleSeleccionMaterial(
      String id, WidgetRef ref, ApunteDb apunte) async {
    final materialNotifier = ref.read(seleccionMaterialesProvider.notifier);
    final itemsNotifier = ref.read(seleccionItemsProvider.notifier);
    final current = ref.read(seleccionMaterialesProvider);
    final currentItems = ref.read(seleccionItemsProvider);

    if (currentItems.contains(id)) {
      itemsNotifier.state = currentItems.difference({id});
      final materialId = await _obtenerMaterialId(apunte);
      if (materialId != null) {
        materialNotifier.state = current.difference({materialId});
      }
    } else {
      itemsNotifier.state = {...currentItems, id};
      final materialId = await _obtenerMaterialId(apunte);
      if (materialId != null) {
        materialNotifier.state = {...current, materialId};
      }
    }
  }

  void _toggleSeleccionMaterialArchivo(
      String id, WidgetRef ref, ArchivoAsignaturaDto a) async {
    final materialNotifier = ref.read(seleccionMaterialesProvider.notifier);
    final itemsNotifier = ref.read(seleccionItemsProvider.notifier);
    final current = ref.read(seleccionMaterialesProvider);
    final currentItems = ref.read(seleccionItemsProvider);

    if (currentItems.contains(id)) {
      itemsNotifier.state = currentItems.difference({id});
      final materialId = await _obtenerMaterialIdArchivo(a);
      if (materialId != null) {
        materialNotifier.state = current.difference({materialId});
      }
    } else {
      itemsNotifier.state = {...currentItems, id};
      final materialId = await _obtenerMaterialIdArchivo(a);
      if (materialId != null) {
        materialNotifier.state = {...current, materialId};
      }
    }
  }

  // ignore: unused_field
  String? _subiendoNombre;
  // ignore: unused_field
  double _progreso = 0;

  Future<void> _subirArchivo() async {
    final FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(withData: true);
    } catch (_) {
      _snack('No se pudo abrir el selector de archivos', error: true);
      return;
    }
    if (result == null || result.files.isEmpty) return;

    final archivo = result.files.first;
    final bytes = archivo.bytes;
    if (bytes == null) {
      _snack('No se pudo leer el archivo seleccionado', error: true);
      return;
    }

    setState(() {
      _subiendoNombre = archivo.name;
      _progreso = 0;
    });

    try {
      final repo = ref.read(archivosRepositoryProvider);
      await repo.subirArchivo(
        asignaturaId: widget.asignaturaId,
        nombreArchivo: archivo.name,
        bytes: bytes,
        onProgreso: (p) {
          if (mounted) setState(() => _progreso = p);
        },
      );
      if (!mounted) return;
      ref.invalidate(archivosAsignaturaProvider(widget.asignaturaId));
      ref.invalidate(conteosAsignaturaProvider(widget.asignaturaId));
      _snack('Archivo subido con éxito');
    } catch (e) {
      _snack('$e', error: true);
    } finally {
      if (mounted) setState(() => _subiendoNombre = null);
    }
  }

  Future<void> _eliminarArchivo(ArchivoAsignaturaDto a) async {
    final confirma = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: SVColors.surfaceContainerLowest,
        title: const Text('Eliminar archivo',
            style: TextStyle(color: SVColors.onSurface)),
        content: Text(
          '¿Eliminar "${a.nombreArchivo}"? Esta acción no se puede deshacer.',
          style: const TextStyle(color: SVColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar',
                  style: TextStyle(color: SVColors.error))),
        ],
      ),
    );
    if (confirma != true) return;
    try {
      await ref.read(archivosRepositoryProvider).eliminarArchivo(a);
      if (!mounted) return;
      ref.invalidate(archivosAsignaturaProvider(widget.asignaturaId));
      ref.invalidate(conteosAsignaturaProvider(widget.asignaturaId));
      _snack('Archivo eliminado');
    } catch (e) {
      _snack('$e', error: true);
    }
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? const Color(0xFFC62828) : null,
    ));
  }

  void _entrarModoSeleccion(WidgetRef ref, String id, ApunteDb apunte) {
    ref.read(modoSeleccionActivoProvider.notifier).state = true;
    _toggleSeleccionMaterial(id, ref, apunte);
  }

  void _entrarModoSeleccionArchivo(
      WidgetRef ref, String id, ArchivoAsignaturaDto a) {
    ref.read(modoSeleccionActivoProvider.notifier).state = true;
    _toggleSeleccionMaterialArchivo(id, ref, a);
  }

  int _contarApuntes(Set<String> items, AsyncValue<List<ApunteDb>> async) {
    return async.whenOrNull(data: (apuntes) {
          return apuntes.where((a) => items.contains(a.id)).length;
        }) ??
        0;
  }

  int _contarArchivos(
      Set<String> items, AsyncValue<List<ArchivoAsignaturaDto>> async) {
    return async.whenOrNull(data: (archivos) {
          return archivos.where((a) => items.contains(a.id)).length;
        }) ??
        0;
  }

  bool _todosSeleccionadosApuntes(
      Set<String> items, AsyncValue<List<ApunteDb>> async) {
    return async.whenOrNull(data: (apuntes) {
          return apuntes.isNotEmpty &&
              apuntes.every((a) => items.contains(a.id));
        }) ??
        false;
  }

  bool _todosSeleccionadosArchivos(
      Set<String> items, AsyncValue<List<ArchivoAsignaturaDto>> async) {
    return async.whenOrNull(data: (archivos) {
          return archivos.isNotEmpty &&
              archivos.every((a) => items.contains(a.id));
        }) ??
        false;
  }

  void _seleccionarTodosApuntes(
      WidgetRef ref, AsyncValue<List<ApunteDb>> async) {
    final items = ref.read(seleccionItemsProvider);
    async.whenData((apuntes) {
      if (_todosSeleccionadosApuntes(items, async)) {
        final ids = apuntes.map((a) => a.id).toSet();
        ref.read(seleccionItemsProvider.notifier).state = items.difference(ids);
        _syncMaterialesTrasDeseleccionar(ref, apuntes);
      } else {
        final nuevos = {...items, ...apuntes.map((a) => a.id)};
        ref.read(seleccionItemsProvider.notifier).state = nuevos;
        _syncMaterialesTrasSeleccionarApuntes(ref, apuntes, nuevos);
      }
    });
  }

  void _seleccionarTodosArchivos(
      WidgetRef ref, AsyncValue<List<ArchivoAsignaturaDto>> async) {
    final items = ref.read(seleccionItemsProvider);
    async.whenData((archivos) {
      if (_todosSeleccionadosArchivos(items, async)) {
        final ids = archivos.map((a) => a.id).toSet();
        ref.read(seleccionItemsProvider.notifier).state = items.difference(ids);
        _syncMaterialesTrasDeseleccionarArchivos(ref, archivos);
      } else {
        final nuevos = {...items, ...archivos.map((a) => a.id)};
        ref.read(seleccionItemsProvider.notifier).state = nuevos;
        _syncMaterialesTrasSeleccionarArchivos(ref, archivos, nuevos);
      }
    });
  }

  void _syncMaterialesTrasDeseleccionar(WidgetRef ref, List<ApunteDb> apuntes) {
    final matNotifier = ref.read(seleccionMaterialesProvider.notifier);
    matNotifier.state = {};
  }

  void _syncMaterialesTrasDeseleccionarArchivos(
      WidgetRef ref, List<ArchivoAsignaturaDto> archivos) {
    final matNotifier = ref.read(seleccionMaterialesProvider.notifier);
    matNotifier.state = {};
  }

  void _syncMaterialesTrasSeleccionarApuntes(
      WidgetRef ref, List<ApunteDb> apuntes, Set<String> nuevosIds) {
    // Material sync happens lazily when quiz is generated
  }

  void _syncMaterialesTrasSeleccionarArchivos(WidgetRef ref,
      List<ArchivoAsignaturaDto> archivos, Set<String> nuevosIds) {
    // Material sync happens lazily when quiz is generated
  }

  Future<void> _eliminarSeleccionados(
      BuildContext context, WidgetRef ref) async {
    final items = ref.read(seleccionItemsProvider);
    if (items.isEmpty) return;

    final count = items.length;
    final confirma = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: SVColors.surfaceContainerLowest,
        title: const Text('Eliminar elementos',
            style: TextStyle(color: SVColors.onSurface)),
        content: Text(
          '¿Eliminar $count elemento${count > 1 ? 's' : ''} seleccionado${count > 1 ? 's' : ''}? Esta acción no se puede deshacer.',
          style: const TextStyle(color: SVColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar',
                  style: TextStyle(color: SVColors.error))),
        ],
      ),
    );
    if (confirma != true) return;

    final apuntesAsync =
        ref.read(apuntesPorAsignaturaProvider(widget.asignaturaId));
    final archivosAsync =
        ref.read(archivosAsignaturaProvider(widget.asignaturaId));
    final apunteIds = apuntesAsync.whenOrNull(
            data: (list) => list.map((a) => a.id).toSet()) ??
        {};
    final archivoIds = archivosAsync.whenOrNull(
            data: (list) => list.map((a) => a.id).toSet()) ??
        {};

    int eliminados = 0;
    for (final id in items) {
      try {
        if (apunteIds.contains(id)) {
          await eliminarApunte(id);
          eliminados++;
        } else if (archivoIds.contains(id)) {
          final archivo = archivosAsync.whenOrNull(
              data: (list) => list.firstWhere((a) => a.id == id));
          if (archivo != null) {
            await ref.read(archivosRepositoryProvider).eliminarArchivo(archivo);
            eliminados++;
          }
        }
      } catch (_) {}
    }

    ref.invalidate(apuntesPorAsignaturaProvider(widget.asignaturaId));
    ref.invalidate(archivosAsignaturaProvider(widget.asignaturaId));
    ref.invalidate(conteosAsignaturaProvider(widget.asignaturaId));
    ref.invalidate(apuntesProvider);

    ref.read(modoSeleccionActivoProvider.notifier).state = false;
    ref.read(seleccionItemsProvider.notifier).state = {};
    ref.read(seleccionMaterialesProvider.notifier).state = {};

    if (mounted) {
      _snack(
          '$eliminados elemento${eliminados != 1 ? 's' : ''} eliminado${eliminados != 1 ? 's' : ''}');
    }
  }

  Future<void> _generarCuestionarioCombinado(
      BuildContext context, WidgetRef ref) async {
    final itemsSeleccionados = ref.read(seleccionItemsProvider).toList();
    final apuntesAsync =
        ref.read(apuntesPorAsignaturaProvider(widget.asignaturaId));
    final archivosAsync =
        ref.read(archivosAsignaturaProvider(widget.asignaturaId));

    final materialIds = <String>[];
    for (final id in itemsSeleccionados) {
      final apunteIds = apuntesAsync.whenOrNull(
              data: (list) => list.map((a) => a.id).toSet()) ??
          {};
      final archivoIds = archivosAsync.whenOrNull(
              data: (list) => list.map((a) => a.id).toSet()) ??
          {};
      if (apunteIds.contains(id)) {
        final apunte = apuntesAsync.whenOrNull(
            data: (list) => list.firstWhere((a) => a.id == id));
        if (apunte != null) {
          final mId = await _obtenerMaterialId(apunte);
          if (mId != null) materialIds.add(mId);
        }
      } else if (archivoIds.contains(id)) {
        final archivo = archivosAsync.whenOrNull(
            data: (list) => list.firstWhere((a) => a.id == id));
        if (archivo != null) {
          final mId = await _obtenerMaterialIdArchivo(archivo);
          if (mId != null) materialIds.add(mId);
        }
      }
    }

    if (materialIds.length < 2) {
      _snack('Selecciona al menos 2 elementos con preguntas generadas',
          error: true);
      return;
    }

    ref.read(modoSeleccionActivoProvider.notifier).state = false;
    final sessionFuture =
        ref.read(crearSesionCombinadaProvider(materialIds).future);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Row(children: [
          SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white)),
          SizedBox(width: 12),
          Text('Generando cuestionario combinado...'),
        ]),
        duration: Duration(seconds: 10)));

    try {
      final session = await sessionFuture;
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        context.push(
            '/academico/practica/${materialIds.first}?sessionId=${session.id}');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFC62828)));
      }
    }
  }
}

class _SeccionTitulo extends StatelessWidget {
  const _SeccionTitulo({
    required this.icono,
    required this.texto,
    required this.color,
  });

  final IconData icono;
  final String texto;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icono, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          texto,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}

Widget _vacio(IconData icono, String titulo, String subtitulo) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 40),
    child: Column(
      children: [
        Icon(icono, size: 44, color: SVColors.outlineVariant),
        const SizedBox(height: 12),
        Text(titulo,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: SVColors.onSurface,
                fontSize: 15,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(subtitulo,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: SVColors.onSurfaceMuted, fontSize: 12.5)),
      ],
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// Pestaña A: Apuntes (conservada para compatibilidad)
// ══════════════════════════════════════════════════════════════════════════════

class _ApuntesTab extends ConsumerWidget {
  const _ApuntesTab({required this.asignaturaId, required this.color});

  final String asignaturaId;
  final Color color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apuntesAsync = ref.watch(apuntesPorAsignaturaProvider(asignaturaId));

    return Stack(
      children: [
        apuntesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _vacio(
              Icons.error_outline, 'No se pudieron cargar los apuntes', '$e'),
          data: (apuntes) {
            if (apuntes.isEmpty) {
              return _vacio(Icons.notes_rounded, 'Sin apuntes todavía',
                  'Pulsa + para crear tu primera nota.');
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
              itemCount: apuntes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) => _ApunteRow(
                apunte: apuntes[i],
                onTap: () => _abrirVisor(context, ref, apuntes[i]),
              ),
            );
          },
        ),
        Positioned(
          right: 20,
          bottom: 20,
          child: FloatingActionButton(
            backgroundColor: color,
            foregroundColor: SVColors.onPrimary,
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onPressed: () => _abrirEditor(context, ref, null),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  /// Abre el editor como una PANTALLA COMPLETA mediante Navigator.push.
  ///
  /// Reemplaza el showModalBottomSheet que causaba el doble ciclo IME
  /// (Input channel destroyed → Starting input dos veces) responsable de
  /// la selección automática de texto en Android.
  Future<void> _abrirEditor(
    BuildContext context,
    WidgetRef ref,
    ApunteDb? existente,
  ) async {
    final guardado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => EditorApunteScreen(
          asignaturaId: asignaturaId,
          existente: existente,
        ),
      ),
    );
    if (guardado == true) {
      ref.invalidate(apuntesPorAsignaturaProvider(asignaturaId));
      ref.invalidate(conteosAsignaturaProvider(asignaturaId));
      ref.invalidate(apuntesProvider);
    }
  }

  /// Abre el apunte en MODO LECTURA (visor). Desde el visor se puede editar,
  /// descargar o eliminar. Al volver, refresca los listados.
  Future<void> _abrirVisor(
    BuildContext context,
    WidgetRef ref,
    ApunteDb apunte,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ApunteVisorScreen(apunte: apunte),
      ),
    );
    ref.invalidate(apuntesPorAsignaturaProvider(asignaturaId));
    ref.invalidate(conteosAsignaturaProvider(asignaturaId));
    ref.invalidate(apuntesProvider);
  }

  Widget _vacio(IconData icono, String titulo, String subtitulo) {
    return ListView(children: [
      const SizedBox(height: 80),
      Icon(icono, size: 48, color: SVColors.outlineVariant),
      const SizedBox(height: 14),
      Text(titulo,
          textAlign: TextAlign.center,
          style: const TextStyle(
              color: SVColors.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w700)),
      const SizedBox(height: 6),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Text(subtitulo,
            textAlign: TextAlign.center,
            style:
                const TextStyle(color: SVColors.onSurfaceMuted, fontSize: 13)),
      ),
    ]);
  }
}

class _ApunteRow extends ConsumerWidget {
  const _ApunteRow({
    required this.apunte,
    required this.onTap,
    this.onLongPress,
    this.modoSeleccion = false,
    this.seleccionado = false,
    this.onToggleSeleccion,
  });

  final ApunteDb apunte;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool modoSeleccion;
  final bool seleccionado;
  final VoidCallback? onToggleSeleccion;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docs = ref
        .watch(docsGuardadosProvider((
          fuenteTipo: 'apunte',
          fuenteId: apunte.id,
        )))
        .valueOrNull;
    final material = ref
        .watch(materialPorFuenteProvider((
          tipoOrigen: 'apunte',
          origenId: apunte.id,
        )))
        .valueOrNull;
    final fecha = DateFormat('d MMM yyyy', 'es').format(apunte.actualizadoEn);
    final tieneResumen = docs?.resumen == true;
    final tieneMapa = docs?.mapa == true;
    final colorBorde = _colorSemaforo(material);

    final bancoData = material != null
        ? ref.watch(bancoPreguntasProvider(material.id))
        : null;
    final tienePreguntas = bancoData != null &&
        bancoData.hasValue &&
        bancoData.requireValue.total > 0;
    final totalPreguntas =
        bancoData?.hasValue == true ? bancoData!.requireValue.total : 0;

    return Material(
      color: SVColors.surfaceContainerLowest,
      borderRadius: SVShapes.standard12,
      elevation: 1,
      shadowColor: SVColors.outlineVariant.withValues(alpha: 0.2),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: colorBorde != null
                ? Border(
                    left: BorderSide(color: colorBorde, width: 3),
                  )
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                if (modoSeleccion) ...[
                  GestureDetector(
                    onTap: onToggleSeleccion,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: seleccionado
                              ? const Color(0xFF3B82F6)
                              : SVColors.outlineVariant,
                          width: 2,
                        ),
                        color: seleccionado
                            ? const Color(0xFF3B82F6)
                            : Colors.transparent,
                      ),
                      child: seleccionado
                          ? const Icon(Icons.check,
                              size: 14, color: Colors.white)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                const Icon(Icons.sticky_note_2_outlined,
                    color: SVColors.onSurfaceMuted, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(apunte.titulo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: SVColors.onSurface,
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(fecha,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: SVColors.onSurfaceMuted, fontSize: 11.5)),
                      if (material?.siguienteRepasoEn != null)
                        Text(
                          'Próximo repaso: ${DateFormat('d MMM', 'es').format(material!.siguienteRepasoEn!)} · EF ${material.facilidad.toStringAsFixed(1)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: SVColors.onSurfaceMuted,
                              fontSize: 11,
                              fontStyle: FontStyle.italic),
                        ),
                    ],
                  ),
                ),
                _buildMenuAcciones(
                  context: context,
                  ref: ref,
                  fuente: FuenteTexto(
                      titulo: apunte.titulo,
                      fuenteId: apunte.id,
                      asignaturaId: apunte.asignaturaId,
                      contenido: apunte.contenido),
                  tieneResumen: tieneResumen,
                  tieneMapa: tieneMapa,
                  tienePreguntas: tienePreguntas,
                  totalPreguntas: totalPreguntas,
                ),
                const Icon(Icons.chevron_right,
                    color: SVColors.outlineVariant, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _iniciarPractica(
  BuildContext context,
  WidgetRef ref,
  FuenteEstudio fuente,
) async {
  final materialId = await _obtenerMaterialIdPorFuente(fuente);
  if (materialId == null) return;

  try {
    final repo = ref.read(practicaRepositoryProvider);
    final banco = await repo.obtenerOCrearBanco(materialId);
    final session =
        await repo.crearSesion(materialId: materialId, bancoId: banco.id);
    if (context.mounted) {
      ref.invalidate(sesionActivaProvider(materialId));
      context.push('/academico/practica/$materialId?sessionId=${session.id}');
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al iniciar práctica: $e'),
          backgroundColor: const Color(0xFFC62828)));
    }
  }
}

Future<void> _iniciarFlashcardsApunte(
    BuildContext context, WidgetRef ref, FuenteEstudio fuente) async {
  final materialId = await _obtenerMaterialIdPorFuente(fuente);
  if (materialId == null || !context.mounted) return;
  context.push('/academico/flashcards/$materialId');
}

void _lanzarGeneracionIndividual(
  BuildContext context,
  WidgetRef ref,
  FuenteEstudio fuente,
  TipoGeneracion tipo,
) {
  final ia = EstudioIaService();
  if (!ia.disponible) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('IA no configurada.'),
        backgroundColor: Color(0xFFC62828)));
    return;
  }
  final notifier = ref.read(artefactoEfimeroProvider.notifier);
  notifier.limpiar();

  final tarea = ref.read(generacionGlobalProvider).registrar(
        titulo: fuente.titulo,
        tipo: tipo.name,
        onNavigate: () {},
      );

  notifier.iniciarYGenerar([fuente], tipo,
      asignaturaId: fuente.asignaturaId, tareaGlobalId: tarea.id);
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => tipo == TipoGeneracion.cuestionario
          ? const CuestionarioFormatoScreen()
          : CentroGeneracionScreen(
              tipo: tipo,
              asignaturaId: fuente.asignaturaId ?? '',
            ),
    ),
  );
}

Future<String?> _obtenerMaterialIdPorFuente(FuenteEstudio fuente) async {
  try {
    final tipo = fuente is FuenteTexto ? 'apunte' : 'archivo';
    final result = await Supabase.instance.client
        .from('materiales_estudio')
        .select('id')
        .eq('tipo_origen', tipo)
        .eq('origen_id', fuente.fuenteId)
        .maybeSingle();
    return result?['id'] as String?;
  } catch (_) {
    return null;
  }
}

Widget _buildMenuAcciones({
  required BuildContext context,
  required WidgetRef ref,
  required FuenteEstudio fuente,
  required bool tieneResumen,
  required bool tieneMapa,
  required bool tienePreguntas,
  required int totalPreguntas,
}) {
  return PopupMenuButton<String>(
    icon:
        const Icon(Icons.more_vert, color: SVColors.onSurfaceVariant, size: 22),
    padding: EdgeInsets.zero,
    constraints: const BoxConstraints(),
    color: SVColors.surfaceContainerLowest,
    shape: RoundedRectangleBorder(borderRadius: SVShapes.standard12),
    onSelected: (action) {
      switch (action) {
        case 'resumen':
          _abrirResumen(context, fuente);
        case 'mapa':
          _abrirMapa(context, fuente);
        case 'generar-resumen':
          _lanzarGeneracionIndividual(
              context, ref, fuente, TipoGeneracion.resumen);
        case 'generar-mapa':
          _lanzarGeneracionIndividual(
              context, ref, fuente, TipoGeneracion.mapaMental);
        case 'generar':
          _lanzarGeneracionIndividual(
              context, ref, fuente, TipoGeneracion.cuestionario);
        case 'practica':
          _iniciarPractica(context, ref, fuente);
        case 'flashcards':
          _iniciarFlashcardsApunte(context, ref, fuente);
      }
    },
    itemBuilder: (_) => [
      if (tieneResumen)
        _menuItem('resumen', Icons.article_outlined, 'Ver resumen')
      else
        _menuItem('generar-resumen', Icons.article_outlined, 'Generar resumen'),
      if (tieneMapa)
        _menuItem('mapa', Icons.account_tree_outlined, 'Ver mapa mental')
      else
        _menuItem(
            'generar-mapa', Icons.account_tree_outlined, 'Generar mapa mental'),
      _menuItem('generar', Icons.auto_awesome_rounded,
          totalPreguntas > 0 ? 'Generar más preguntas' : 'Generar preguntas'),
      if (tienePreguntas)
        _menuItem('practica', Icons.play_arrow_rounded,
            'Iniciar práctica ($totalPreguntas)'),
      if (tienePreguntas)
        _menuItem('flashcards', Icons.style_outlined, 'Estudiar Flashcards'),
    ],
  );
}

PopupMenuItem<String> _menuItem(String value, IconData icon, String text) {
  return PopupMenuItem<String>(
    value: value,
    child: Row(
      children: [
        Icon(icon, size: 18, color: SVColors.primary),
        const SizedBox(width: 12),
        Text(text,
            style: const TextStyle(
                color: SVColors.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w500)),
      ],
    ),
  );
}

void _abrirResumen(BuildContext context, FuenteEstudio fuente) {
  Navigator.of(context).push(MaterialPageRoute(
    builder: (_) => ResumenIaScreen(fuente: fuente),
  ));
}

void _abrirMapa(BuildContext context, FuenteEstudio fuente) {
  Navigator.of(context).push(MaterialPageRoute(
    builder: (_) => MapaMentalScreen(fuente: fuente),
  ));
}

Color? _colorSemaforo(MaterialEstudioDb? material) {
  if (material == null) return null;
  final ahora = DateTime.now();
  if (material.siguienteRepasoEn != null &&
      material.siguienteRepasoEn!.isBefore(ahora)) {
    return const Color(0xFFEF5350); // rojo — atrasado
  }
  return switch (material.estadoDominio) {
    'dominado' => const Color(0xFF4CAF50), // verde
    'en_progreso' => const Color(0xFFFFC107), // amarillo
    'necesita_repaso' => const Color(0xFFEF5350), // rojo
    _ => null,
  };
}

// ══════════════════════════════════════════════════════════════════════════════
// EditorApunteScreen  — editor de apuntes Markdown (Clean UI)
// ══════════════════════════════════════════════════════════════════════════════

/// Editor de apuntes a pantalla completa con estética Clean UI.
///
/// Diseño minimalista tipo "papel": título grande sin recuadro, cuerpo sin
/// bordes y barra de formato fija que flota sobre el teclado.
///
/// Manejo de selección robusto en Android/One UI: el cuerpo es un
/// `TextField` con `maxLines: null` dentro de un `SingleChildScrollView`
/// (sin `expands: true`, cuyo scroll interno entra en conflicto con el
/// reconocedor de selección y provoca selecciones espurias al tocar). Un
/// `GestureDetector` translúcido captura los toques en la zona vacía para
/// posicionar el cursor; sobre el texto, el gesto nativo del campo decide:
/// toque = cursor, pulsación sostenida = selección.
class EditorApunteScreen extends ConsumerStatefulWidget {
  const EditorApunteScreen({
    required this.asignaturaId,
    this.existente,
    super.key,
  });

  final String asignaturaId;
  final ApunteDb? existente;

  @override
  ConsumerState<EditorApunteScreen> createState() => _EditorApunteScreenState();
}

class _EditorApunteScreenState extends ConsumerState<EditorApunteScreen> {
  late final TextEditingController _titulo;
  late final TextEditingController _contenido;
  late final FocusNode _contenidoFocus;

  bool _guardando = false;
  bool _vistaPrevia = false;

  @override
  void initState() {
    super.initState();
    _titulo = TextEditingController(text: widget.existente?.titulo ?? '');
    _contenido = TextEditingController(text: widget.existente?.contenido ?? '');
    _contenidoFocus = FocusNode();
  }

  @override
  void dispose() {
    _titulo.dispose();
    _contenido.dispose();
    _contenidoFocus.dispose();
    super.dispose();
  }

  // ── Guardado ─────────────────────────────────────────────────────────────

  Future<void> _guardar() async {
    final titulo = _titulo.text.trim();
    if (titulo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El título no puede estar vacío.')),
      );
      return;
    }
    setState(() => _guardando = true);
    try {
      if (widget.existente == null) {
        await crearApunte(
          titulo: titulo,
          contenido: _contenido.text,
          asignaturaId: widget.asignaturaId,
        );
      } else {
        await actualizarApunte(
          id: widget.existente!.id,
          titulo: titulo,
          contenido: _contenido.text,
          asignaturaId: widget.asignaturaId,
          visibilidad: widget.existente!.visibilidad,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _guardando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo guardar: $e')),
        );
      }
    }
  }

  // ── Inserción de Markdown ─────────────────────────────────────────────────

  /// Aplica un nuevo valor al controlador de forma segura para el IME.
  ///
  /// En Android (especialmente One UI / Samsung) mutar `controller.value`
  /// mientras el campo está desenfocado o el teclado mantiene una región de
  /// composición activa desincroniza el estado de edición. Esa desincronización
  /// hace que los toques posteriores se interpreten como selección en lugar de
  /// posicionar el cursor. Reafirmamos el foco y limpiamos la composición para
  /// que el IME vuelva a un estado coherente con un cursor colapsado.
  void _aplicarValor(String nuevoTexto, int cursor) {
    if (!_contenidoFocus.hasFocus) {
      _contenidoFocus.requestFocus();
    }
    final pos = cursor.clamp(0, nuevoTexto.length);
    _contenido.value = TextEditingValue(
      text: nuevoTexto,
      selection: TextSelection.collapsed(offset: pos),
      composing: TextRange.empty,
    );
  }

  /// Devuelve una selección válida; si el campo nunca recibió foco, apunta al
  /// final del texto en lugar de a un offset inválido (-1).
  TextSelection _seleccionSegura(TextEditingValue v) {
    final sel = v.selection;
    if (!sel.isValid) {
      return TextSelection.collapsed(offset: v.text.length);
    }
    return sel;
  }

  void _insertarMarkdown(String antes, String despues) {
    final v = _contenido.value;
    final sel = _seleccionSegura(v);
    final texto = v.text;

    final inicio = sel.start.clamp(0, texto.length);
    final fin = sel.end.clamp(0, texto.length);
    final seleccionado = texto.substring(inicio, fin);

    final reemplazo =
        seleccionado.isEmpty ? '$antes$despues' : '$antes$seleccionado$despues';

    final nuevoTexto = texto.replaceRange(inicio, fin, reemplazo);
    final nuevaPos = seleccionado.isEmpty
        ? inicio + antes.length
        : inicio + reemplazo.length;

    _aplicarValor(nuevoTexto, nuevaPos);
  }

  void _insertarLinea(String prefijo) {
    final v = _contenido.value;
    final texto = v.text;
    final inicio = _seleccionSegura(v).start.clamp(0, texto.length);

    final antes = texto.substring(0, inicio);
    final salto = antes.isEmpty || antes.endsWith('\n') ? '' : '\n';
    final resto = texto.substring(inicio);
    final nuevoTexto = '$antes$salto$prefijo$resto';
    final nuevaPos = inicio + salto.length + prefijo.length;

    _aplicarValor(nuevoTexto, nuevaPos);
  }

  /// Enfoca el campo de contenido y coloca el cursor al final.
  ///
  /// Se invoca cuando el usuario toca cualquier zona vacía del editor (por
  /// debajo del texto). Un toque simple SIEMPRE posiciona el cursor; la
  /// selección queda reservada para la pulsación sostenida sobre el texto,
  /// que es el gesto nativo del [TextField].
  void _enfocarContenidoAlFinal() {
    if (!_contenidoFocus.hasFocus) {
      _contenidoFocus.requestFocus();
    }
    _contenido.selection =
        TextSelection.collapsed(offset: _contenido.text.length);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SVColors.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: SVColors.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon:
              const Icon(Icons.close_rounded, color: SVColors.onSurfaceVariant),
          onPressed: () => Navigator.of(context).pop(false),
          tooltip: 'Cancelar',
        ),
        title: Text(
          widget.existente == null ? 'Nuevo apunte' : 'Editar apunte',
          style: const TextStyle(
            color: SVColors.onSurfaceMuted,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _vistaPrevia ? Icons.edit_outlined : Icons.visibility_outlined,
              size: 22,
            ),
            color: _vistaPrevia ? SVColors.primary : SVColors.onSurfaceVariant,
            tooltip: _vistaPrevia ? 'Editar' : 'Vista previa',
            onPressed: () {
              _contenidoFocus.unfocus();
              setState(() => _vistaPrevia = !_vistaPrevia);
            },
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4, right: 12),
            child: FilledButton(
              onPressed: _guardando ? null : _guardar,
              style: FilledButton.styleFrom(
                backgroundColor: SVColors.primary,
                foregroundColor: SVColors.onPrimary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                minimumSize: const Size(0, 38),
                shape:
                    const RoundedRectangleBorder(borderRadius: SVShapes.pill),
              ),
              child: _guardando
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: SVColors.onPrimary),
                    )
                  : const Text('Guardar',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Título ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: TextField(
                controller: _titulo,
                cursorColor: SVColors.primary,
                maxLines: 1,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                style: const TextStyle(
                  color: SVColors.onSurface,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
                decoration: const InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: 'Título',
                  hintStyle: TextStyle(
                    color: SVColors.outline,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                onSubmitted: (_) => _enfocarContenidoAlFinal(),
              ),
            ),
            const SizedBox(height: 6),

            // ── Cuerpo: editor o vista previa ──────────────────────────────
            // El cuerpo se envuelve en un GestureDetector translúcido para que
            // un toque en CUALQUIER zona (incluida la parte vacía bajo el
            // texto) posicione el cursor en lugar de no hacer nada. Sobre el
            // texto, el propio TextField gestiona el gesto nativo: toque =
            // cursor, pulsación sostenida = selección. Se evita `expands:true`
            // (cuyo scroll interno entra en conflicto con el reconocedor de
            // selección en One UI/Samsung y dispara selecciones espurias) en
            // favor de `maxLines:null` dentro de un scroll externo.
            Expanded(
              child: _vistaPrevia
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _VistaPreviaMarkdown(contenido: _contenido.text),
                    )
                  : GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: _enfocarContenidoAlFinal,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                        child: TextField(
                          controller: _contenido,
                          focusNode: _contenidoFocus,
                          cursorColor: SVColors.primary,
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          textCapitalization: TextCapitalization.sentences,
                          style: const TextStyle(
                            color: SVColors.onSurface,
                            height: 1.7,
                            fontSize: 15.5,
                          ),
                          decoration: const InputDecoration(
                            isCollapsed: true,
                            border: InputBorder.none,
                            hintText:
                                'Empieza a escribir…\n\nUsa Markdown: # títulos, **negrita**, *cursiva*, - listas',
                            hintStyle: TextStyle(
                              color: SVColors.outline,
                              height: 1.7,
                              fontSize: 15.5,
                            ),
                          ),
                        ),
                      ),
                    ),
            ),

            // ── Barra inferior: formato + contador (solo en edición) ───────
            if (!_vistaPrevia) _barraInferior(),
          ],
        ),
      ),
    );
  }

  /// Barra fija inferior que flota sobre el teclado: herramientas de formato
  /// a la izquierda (scroll horizontal) y recuento de palabras a la derecha.
  Widget _barraInferior() {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: SVColors.surfaceContainerLowest,
        border: Border(
          top: BorderSide(color: SVColors.outlineVariant, width: 1),
        ),
      ),
      child: SizedBox(
        height: 50,
        child: Row(
          children: [
            Expanded(
              child: _BarraFormato(
                onNegrita: () => _insertarMarkdown('**', '**'),
                onCursiva: () => _insertarMarkdown('*', '*'),
                onTitulo: () => _insertarLinea('# '),
                onSubtitulo: () => _insertarLinea('## '),
                onLista: () => _insertarLinea('- '),
                onNumerada: () => _insertarLinea('1. '),
                onCodigo: () => _insertarMarkdown('`', '`'),
                onCita: () => _insertarLinea('> '),
                onSeparador: () => _insertarLinea('\n---\n'),
                onEnlace: () => _insertarMarkdown('[', '](url)'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _contenido,
                builder: (context, value, _) {
                  final palabras = value.text.trim().isEmpty
                      ? 0
                      : value.text.trim().split(RegExp(r'\s+')).length;
                  return Text(
                    '$palabras palabras',
                    style: const TextStyle(
                        color: SVColors.onSurfaceMuted, fontSize: 12),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Barra de formato Markdown
// ══════════════════════════════════════════════════════════════════════════════

/// Botón de la barra de formato.
///
/// Usa [ExcludeFocus] + [GestureDetector] (no [IconButton]) para NO robar el
/// foco al editor: así el teclado permanece abierto y el cursor intacto al
/// insertar marcas Markdown. Se usa `onTap` (no `onTapDown`) para no disparar
/// inserciones a mitad de gesto al desplazar horizontalmente la barra.
class _FormatBtn extends StatelessWidget {
  const _FormatBtn({
    required this.icono,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icono;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ExcludeFocus(
      child: Tooltip(
        message: tooltip,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 44,
            height: 50,
            alignment: Alignment.center,
            child: Icon(icono, size: 21, color: SVColors.onSurfaceVariant),
          ),
        ),
      ),
    );
  }
}

class _BarraFormato extends StatelessWidget {
  const _BarraFormato({
    required this.onNegrita,
    required this.onCursiva,
    required this.onTitulo,
    required this.onSubtitulo,
    required this.onLista,
    required this.onNumerada,
    required this.onCodigo,
    required this.onCita,
    required this.onSeparador,
    required this.onEnlace,
  });

  final VoidCallback onNegrita;
  final VoidCallback onCursiva;
  final VoidCallback onTitulo;
  final VoidCallback onSubtitulo;
  final VoidCallback onLista;
  final VoidCallback onNumerada;
  final VoidCallback onCodigo;
  final VoidCallback onCita;
  final VoidCallback onSeparador;
  final VoidCallback onEnlace;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        children: [
          _FormatBtn(
              icono: Icons.format_bold, tooltip: 'Negrita', onTap: onNegrita),
          _FormatBtn(
              icono: Icons.format_italic, tooltip: 'Cursiva', onTap: onCursiva),
          _sep(),
          _FormatBtn(icono: Icons.title, tooltip: 'Título', onTap: onTitulo),
          _FormatBtn(
              icono: Icons.text_fields,
              tooltip: 'Subtítulo',
              onTap: onSubtitulo),
          _sep(),
          _FormatBtn(
              icono: Icons.format_list_bulleted,
              tooltip: 'Lista',
              onTap: onLista),
          _FormatBtn(
              icono: Icons.format_list_numbered,
              tooltip: 'Numerada',
              onTap: onNumerada),
          _sep(),
          _FormatBtn(icono: Icons.code, tooltip: 'Código', onTap: onCodigo),
          _FormatBtn(icono: Icons.format_quote, tooltip: 'Cita', onTap: onCita),
          _FormatBtn(
              icono: Icons.horizontal_rule,
              tooltip: 'Separador',
              onTap: onSeparador),
          _FormatBtn(icono: Icons.link, tooltip: 'Enlace', onTap: onEnlace),
        ],
      ),
    );
  }

  Widget _sep() => Container(
        width: 1,
        height: 22,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        color: SVColors.outlineVariant,
      );
}

// ══════════════════════════════════════════════════════════════════════════════
// Vista previa Markdown
// ══════════════════════════════════════════════════════════════════════════════

class _VistaPreviaMarkdown extends StatelessWidget {
  const _VistaPreviaMarkdown({required this.contenido});

  final String contenido;

  @override
  Widget build(BuildContext context) {
    if (contenido.trim().isEmpty) {
      return const Center(
        child: Text('Sin contenido para previsualizar',
            style: TextStyle(color: SVColors.onSurfaceMuted, fontSize: 13)),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: DefaultTextStyle(
        style: const TextStyle(
            color: SVColors.onSurface, fontSize: 14, height: 1.5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _parsear(contenido),
        ),
      ),
    );
  }

  List<Widget> _parsear(String md) {
    final widgets = <Widget>[];
    for (final linea in md.split('\n')) {
      if (linea.startsWith('### ')) {
        widgets.add(_txt(linea.substring(4), 16, FontWeight.w700));
      } else if (linea.startsWith('## ')) {
        widgets.add(_txt(linea.substring(3), 18, FontWeight.w700));
      } else if (linea.startsWith('# ')) {
        widgets.add(_txt(linea.substring(2), 20, FontWeight.w800));
      } else if (linea.startsWith('- ') || linea.startsWith('* ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(left: 8, top: 2, bottom: 2),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('• ',
                style: TextStyle(color: SVColors.onSurfaceVariant)),
            Expanded(child: _txt(linea.substring(2), 14, FontWeight.w400)),
          ]),
        ));
      } else if (linea.startsWith('> ')) {
        widgets.add(Container(
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.only(left: 10),
          decoration: BoxDecoration(
            border: Border(
                left: BorderSide(
                    color: SVColors.primary.withValues(alpha: 0.5), width: 3)),
          ),
          child: _txt(linea.substring(2), 14, FontWeight.w400,
              color: SVColors.onSurfaceVariant),
        ));
      } else if (linea == '---') {
        widgets.add(const Padding(
          padding: EdgeInsets.symmetric(vertical: 6),
          child: Divider(color: SVColors.outlineVariant),
        ));
      } else if (linea.trim().isEmpty) {
        widgets.add(const SizedBox(height: 6));
      } else {
        widgets.add(_txt(linea, 14, FontWeight.w400));
      }
    }
    return widgets;
  }

  Widget _txt(String texto, double size, FontWeight peso, {Color? color}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Text.rich(
          _inline(texto),
          style: TextStyle(
              fontSize: size,
              fontWeight: peso,
              color: color ?? SVColors.onSurface),
        ),
      );

  TextSpan _inline(String texto) {
    final spans = <InlineSpan>[];
    final exp = RegExp(r'(\*\*.*?\*\*|\*.*?\*|`.*?`)');
    int last = 0;
    for (final m in exp.allMatches(texto)) {
      if (m.start > last) {
        spans.add(TextSpan(text: texto.substring(last, m.start)));
      }
      final val = m.group(0)!;
      if (val.startsWith('**')) {
        spans.add(TextSpan(
            text: val.substring(2, val.length - 2),
            style: const TextStyle(fontWeight: FontWeight.w800)));
      } else if (val.startsWith('*')) {
        spans.add(TextSpan(
            text: val.substring(1, val.length - 1),
            style: const TextStyle(fontStyle: FontStyle.italic)));
      } else {
        spans.add(TextSpan(
            text: val.substring(1, val.length - 1),
            style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                backgroundColor: SVColors.surfaceContainerHighest,
                color: SVColors.onSurfaceVariant)));
      }
      last = m.end;
    }
    if (last < texto.length) spans.add(TextSpan(text: texto.substring(last)));
    return TextSpan(
        children: spans.isEmpty ? null : spans,
        text: spans.isEmpty ? texto : null);
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Pestaña B: Archivos
// ══════════════════════════════════════════════════════════════════════════════

class _ArchivosTab extends ConsumerStatefulWidget {
  const _ArchivosTab({required this.asignaturaId, required this.color});

  final String asignaturaId;
  final Color color;

  @override
  ConsumerState<_ArchivosTab> createState() => _ArchivosTabState();
}

class _ArchivosTabState extends ConsumerState<_ArchivosTab> {
  String? _subiendoNombre;
  double _progreso = 0;

  Future<void> _subir() async {
    final FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(withData: true);
    } catch (_) {
      _snack('No se pudo abrir el selector de archivos', error: true);
      return;
    }
    if (result == null || result.files.isEmpty) return;

    final archivo = result.files.first;
    final bytes = archivo.bytes;
    if (bytes == null) {
      _snack('No se pudo leer el archivo seleccionado', error: true);
      return;
    }

    setState(() {
      _subiendoNombre = archivo.name;
      _progreso = 0;
    });

    try {
      final repo = ref.read(archivosRepositoryProvider);
      await repo.subirArchivo(
        asignaturaId: widget.asignaturaId,
        nombreArchivo: archivo.name,
        bytes: bytes,
        onProgreso: (p) {
          if (mounted) setState(() => _progreso = p);
        },
      );
      if (!mounted) return;
      ref.invalidate(archivosAsignaturaProvider(widget.asignaturaId));
      ref.invalidate(conteosAsignaturaProvider(widget.asignaturaId));
      _snack('Archivo subido con éxito');
    } catch (e) {
      _snack('$e', error: true);
    } finally {
      if (mounted) setState(() => _subiendoNombre = null);
    }
  }

  Future<void> _eliminar(ArchivoAsignaturaDto a) async {
    final confirma = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: SVColors.surfaceContainerLowest,
        title: const Text('Eliminar archivo',
            style: TextStyle(color: SVColors.onSurface)),
        content: Text(
          '¿Eliminar "${a.nombreArchivo}"? Esta acción no se puede deshacer.',
          style: const TextStyle(color: SVColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar',
                  style: TextStyle(color: SVColors.error))),
        ],
      ),
    );
    if (confirma != true) return;
    try {
      await ref.read(archivosRepositoryProvider).eliminarArchivo(a);
      if (!mounted) return;
      ref.invalidate(archivosAsignaturaProvider(widget.asignaturaId));
      ref.invalidate(conteosAsignaturaProvider(widget.asignaturaId));
      _snack('Archivo eliminado');
    } catch (e) {
      _snack('$e', error: true);
    }
  }

  void _abrirArchivo(ArchivoAsignaturaDto archivo) =>
      context.push('/academico/archivo/visor', extra: archivo);

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? const Color(0xFFC62828) : null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final archivosAsync =
        ref.watch(archivosAsignaturaProvider(widget.asignaturaId));

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _subiendoNombre != null ? null : _subir,
            style: OutlinedButton.styleFrom(
              foregroundColor: widget.color,
              side: BorderSide(color: widget.color.withValues(alpha: 0.5)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: const RoundedRectangleBorder(
                  borderRadius: SVShapes.standard12),
            ),
            icon: const Icon(Icons.upload_file_outlined, size: 20),
            label: const Text('Subir archivo',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
      ),
      Expanded(
        child: archivosAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _vacio(
              Icons.error_outline, 'No se pudieron cargar los archivos', '$e'),
          data: (archivos) {
            final tieneSubida = _subiendoNombre != null;
            if (archivos.isEmpty && !tieneSubida) {
              return _vacio(
                Icons.folder_outlined,
                'Sin archivos todavía',
                'Sube PDFs, imágenes o diapositivas de esta asignatura.',
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              itemCount: archivos.length + (tieneSubida ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                if (tieneSubida && i == 0) {
                  return ArchivoSubiendoTile(
                      nombre: _subiendoNombre!, progreso: _progreso);
                }
                final archivo = archivos[i - (tieneSubida ? 1 : 0)];
                return ArchivoTile(
                  archivo: archivo,
                  onAbrir: () => _abrirArchivo(archivo),
                  onEliminar: () => _eliminar(archivo),
                );
              },
            );
          },
        ),
      ),
    ]);
  }

  Widget _vacio(IconData icono, String titulo, String subtitulo) {
    return ListView(children: [
      const SizedBox(height: 70),
      Icon(icono, size: 48, color: SVColors.outlineVariant),
      const SizedBox(height: 14),
      Text(titulo,
          textAlign: TextAlign.center,
          style: const TextStyle(
              color: SVColors.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w700)),
      const SizedBox(height: 6),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Text(subtitulo,
            textAlign: TextAlign.center,
            style:
                const TextStyle(color: SVColors.onSurfaceMuted, fontSize: 13)),
      ),
    ]);
  }
}

class _BarraAccionesSeleccion extends StatelessWidget {
  const _BarraAccionesSeleccion({
    required this.seleccionadosCount,
    required this.onEliminar,
    this.onCuestionario,
    required this.color,
    required this.onCancelar,
  });

  final int seleccionadosCount;
  final VoidCallback onEliminar;
  final VoidCallback? onCuestionario;
  final Color color;
  final VoidCallback onCancelar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: BoxDecoration(
        color: SVColors.surfaceContainerLowest,
        border: const Border(
          top: BorderSide(color: SVColors.outlineVariant, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: SVColors.outlineVariant.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            GestureDetector(
              onTap: onCancelar,
              child: const Icon(Icons.close,
                  color: SVColors.onSurfaceMuted, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              '$seleccionadosCount seleccionado${seleccionadosCount != 1 ? 's' : ''}',
              style: const TextStyle(
                color: SVColors.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: onEliminar,
              icon: const Icon(Icons.delete_outline,
                  color: SVColors.error, size: 22),
              tooltip: 'Eliminar',
            ),
            const SizedBox(width: 4),
            if (onCuestionario != null)
              FilledButton.icon(
                onPressed: onCuestionario,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                label: const Text('Cuestionario',
                    style:
                        TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              ),
          ],
        ),
      ),
    );
  }
}
