import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/design_system/sv_colors.dart';
import '../../../core/design_system/sv_shapes.dart';
import '../../../shared/models/db_models.dart';
import '../../../shared/widgets/feature_scaffold.dart';
import '../../academico/application/asignaturas_provider.dart';
import '../application/retos_provider.dart';
import 'adjuntar_tarea_sheet.dart';
import 'vincular_sheet.dart';

// =============================================================================
// Paleta local (CLEAN UI · Flat Design sobre el sistema de diseño SV)
// =============================================================================
Color _difColor(String d) => switch (d) {
      'baja' => const Color(0xFF10B981),
      'alta' => const Color(0xFFEF4444),
      _ => const Color(0xFFF59E0B),
    };

const _paletaAsig = [
  Color(0xFF3B82F6),
  Color(0xFF8B5CF6),
  Color(0xFF10B981),
  Color(0xFFF59E0B),
  Color(0xFFEF4444),
  Color(0xFF06B6D4),
  Color(0xFFEC4899),
];
Color _colorAsignatura(String key) =>
    _paletaAsig[key.hashCode.abs() % _paletaAsig.length];

const _sombraSuave = [
  BoxShadow(
    color: Color(0x0F000000),
    blurRadius: 14,
    offset: Offset(0, 4),
  ),
];

/// Pantalla unificada de creación de retos.
///
/// Un único flujo para todos los retos: las tareas son opcionales. Si el
/// usuario añade tareas se persisten como hitos (`hitos_de_reto`); si no,
/// el reto se crea sin hitos. El usuario nunca ve la distinción simple/complejo.
class CrearRetoScreen extends ConsumerStatefulWidget {
  const CrearRetoScreen({
    this.prefilledSubjectId,
    this.prefilledSubjectName,
    this.prefilledTitle,
    this.asignaturaFija = false,
    super.key,
  });

  final String? prefilledSubjectId;
  final String? prefilledSubjectName;
  final String? prefilledTitle;

  /// Si `true`, la asignatura pre-rellenada no se puede cambiar.
  final bool asignaturaFija;

  @override
  ConsumerState<CrearRetoScreen> createState() => _CrearRetoScreenState();
}

class _CrearRetoScreenState extends ConsumerState<CrearRetoScreen> {
  static const _maxTareas = 12;

  final _tituloCtrl = TextEditingController();
  String _dificultad = 'media';
  String? _asignaturaId;
  String? _asignaturaNombre;
  bool _asignaturaFija = false;
  String? _entidadVincId;
  String? _entidadVincTipo;
  String? _entidadVincTitulo;
  String _visibilidad = 'private';
  DateTime _fechaInicio = DateTime.now();
  DateTime _fechaFin = DateTime.now().add(const Duration(days: 7));
  bool _guardando = false;

  final List<_TareaDraft> _tareas = [];

  bool get _tituloValido => _tituloCtrl.text.trim().length >= 5;

  @override
  void initState() {
    super.initState();
    if (widget.prefilledTitle != null) {
      _tituloCtrl.text = widget.prefilledTitle!;
    }
    if (widget.prefilledSubjectId != null) {
      _asignaturaId = widget.prefilledSubjectId;
      _asignaturaNombre = widget.prefilledSubjectName;
      _asignaturaFija = widget.asignaturaFija;
      if (_asignaturaNombre == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final asignaturas =
              ref.read(asignaturasActivasProvider).valueOrNull ?? [];
          final match = asignaturas
              .where((a) => a.id == widget.prefilledSubjectId)
              .firstOrNull;
          if (match != null && mounted) {
            setState(() => _asignaturaNombre = match.nombre);
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    for (final t in _tareas) {
      t.controller.dispose();
    }
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Acciones
  // ---------------------------------------------------------------------------
  void _agregarTarea() {
    if (_tareas.length >= _maxTareas) return;
    setState(() => _tareas.add(_TareaDraft()));
    _enfocarUltimaTarea();
  }

  void _enfocarUltimaTarea() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final last = _tareas.isNotEmpty ? _tareas.last : null;
      last?.focusNode.requestFocus();
    });
  }

  void _eliminarTarea(int index) {
    setState(() {
      _tareas[index].dispose();
      _tareas.removeAt(index);
    });
  }

  void _ciclarDificultadTarea(int index) {
    setState(() {
      final t = _tareas[index];
      t.dificultad = switch (t.dificultad) {
        'baja' => 'media',
        'media' => 'alta',
        _ => 'baja',
      };
    });
  }

  Future<void> _adjuntarTarea(int index) async {
    final tarea = _tareas[index];
    // Asignatura efectiva: la propia de la tarea o, si no, la del reto.
    final asignaturaEfectiva = tarea.asignaturaId ?? _asignaturaId;
    final res = await mostrarAdjuntarTareaSheet(
      context,
      asignaturaId: asignaturaEfectiva,
    );
    if (res == null || !mounted) return;
    setState(() {
      final t = _tareas[index];
      if (res.apunteId != null) {
        t.apunteId = res.apunteId;
        t.apunteTitulo = res.titulo;
        t.archivoId = null;
        t.archivoNombre = null;
      } else if (res.archivoId != null) {
        t.archivoId = res.archivoId;
        t.archivoNombre = res.titulo;
        t.apunteId = null;
        t.apunteTitulo = null;
      }
    });
  }

  void _quitarAdjuntoTarea(int index) {
    setState(() {
      _tareas[index]
        ..apunteId = null
        ..apunteTitulo = null
        ..archivoId = null
        ..archivoNombre = null;
    });
  }

  Future<void> _seleccionarAsignaturaReto() async {
    final r = await _pickAsignatura();
    if (r == null || !mounted) return;
    setState(() {
      _asignaturaId = r.$1.isEmpty ? null : r.$1;
      _asignaturaNombre = r.$1.isEmpty ? null : r.$2;
    });
  }

  Future<void> _seleccionarAsignaturaTarea(int index) async {
    final r = await _pickAsignatura();
    if (r == null || !mounted) return;
    setState(() {
      _tareas[index].asignaturaId = r.$1.isEmpty ? null : r.$1;
      _tareas[index].asignaturaNombre = r.$1.isEmpty ? null : r.$2;
    });
  }

  Future<(String, String)?> _pickAsignatura() async {
    // Esperamos a que el provider resuelva: antes, el primer clic mostraba
    // la lista vacía porque el future aún no había cargado.
    final asignaturas = await ref.read(asignaturasActivasProvider.future);
    if (!mounted) return null;
    return showModalBottomSheet<(String, String)?>(
      context: context,
      backgroundColor: SVColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Text('Elegir asignatura',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: SVColors.onSurface)),
            ),
            ListTile(
              leading: const Icon(Icons.block,
                  size: 20, color: SVColors.onSurfaceMuted),
              title: const Text('Sin asignatura'),
              onTap: () => Navigator.pop(ctx, ('', '')),
            ),
            if (asignaturas.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('No tienes asignaturas activas.',
                    style: TextStyle(color: SVColors.onSurfaceMuted)),
              )
            else
              ...asignaturas.map((AsignaturaDb a) => ListTile(
                    leading: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: _colorAsignatura(a.id).withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.label_outline,
                          size: 12, color: _colorAsignatura(a.id)),
                    ),
                    title: Text(a.nombre),
                    onTap: () => Navigator.pop(ctx, (a.id, a.nombre)),
                  )),
          ],
        ),
      ),
    );
  }

  Future<void> _seleccionarEntidad() async {
    final vinculo = await mostrarVincularSheet(
      context,
      asignaturaId: _asignaturaId,
    );
    if (vinculo == null || !mounted) return;
    setState(() {
      if (vinculo.esVacio) {
        _entidadVincId = null;
        _entidadVincTipo = null;
        _entidadVincTitulo = null;
      } else {
        _entidadVincId = vinculo.id;
        _entidadVincTipo = vinculo.tipo;
        _entidadVincTitulo = vinculo.titulo;
      }
    });
  }

  Future<void> _seleccionarFecha({required bool inicio}) async {
    final base = inicio ? _fechaInicio : _fechaFin;
    final min =
        inicio ? DateTime(2020) : _fechaInicio.add(const Duration(days: 1));
    final sel = await showDatePicker(
      context: context,
      initialDate: base.isBefore(min) ? min : base,
      firstDate: min,
      lastDate: DateTime(2100),
      helpText: inicio ? 'Fecha de inicio' : 'Fecha de fin',
    );
    if (sel == null || !mounted) return;
    setState(() {
      if (inicio) {
        _fechaInicio = DateTime(sel.year, sel.month, sel.day);
        if (!_fechaFin.isAfter(_fechaInicio)) {
          _fechaFin = _fechaInicio.add(const Duration(days: 1));
        }
      } else {
        _fechaFin = DateTime(sel.year, sel.month, sel.day, 23, 59);
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Persistencia (mapeo directo a `retos` + `hitos_de_reto`)
  // ---------------------------------------------------------------------------
  Future<void> _crearReto() async {
    if (_guardando) return;

    final titulo = _tituloCtrl.text.trim();
    if (titulo.length < 5) {
      _aviso('El título debe tener al menos 5 caracteres.');
      return;
    }

    // Solo cuentan las tareas con texto; el resto se descarta.
    final tareasValidas = _tareas.where((t) => t.titulo.isNotEmpty).toList();
    for (final t in tareasValidas) {
      if (t.titulo.length < 3) {
        _aviso('Cada tarea debe tener al menos 3 caracteres.');
        return;
      }
    }
    if (!_fechaFin.isAfter(_fechaInicio)) {
      _aviso('La fecha de fin debe ser posterior al inicio.');
      return;
    }

    setState(() => _guardando = true);
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) throw Exception('Sesión no activa');

      final retoMap = await client
          .from('retos')
          .insert({
            'usuario_id': user.id,
            'titulo': titulo,
            'tipo': _asignaturaId != null ? 'academic' : 'fitness',
            'meta': titulo,
            'visibilidad': _visibilidad,
            'dificultad': _dificultad,
            if (_asignaturaId != null) 'asignatura_id': _asignaturaId,
            if (_entidadVincId != null) 'entidad_vinculada_id': _entidadVincId,
            if (_entidadVincTipo != null)
              'entidad_vinculada_tipo': _entidadVincTipo,
            'fecha_inicio': _fechaInicio.toIso8601String(),
            'fecha_fin': _fechaFin.toIso8601String(),
          })
          .select('id')
          .single();
      final retoId = retoMap['id'] as String;

      // Si el usuario añadió tareas → hitos con peso uniforme.
      if (tareasValidas.isNotEmpty) {
        final peso = 100.0 / tareasValidas.length;
        final hitos = <Map<String, dynamic>>[];
        for (var i = 0; i < tareasValidas.length; i++) {
          final t = tareasValidas[i];
          // Herencia: si la tarea no tiene asignatura, hereda la del reto.
          final asigId = t.asignaturaId ?? _asignaturaId;
          hitos.add({
            'reto_id': retoId,
            'titulo': t.titulo,
            'porcentaje_peso': double.parse(peso.toStringAsFixed(2)),
            'indice_orden': i + 1,
            'progreso_actual': 0,
            'esta_completado': false,
            'dificultad': t.dificultad,
            if (asigId != null) 'asignatura_id': asigId,
            if (t.apunteId != null) 'apunte_id': t.apunteId,
            if (t.archivoId != null) 'archivo_id': t.archivoId,
          });
        }
        await client.from('hitos_de_reto').insert(hitos);
      }

      ref.invalidate(retosProvider);
      ref.invalidate(todosRetosProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reto creado')),
      );
      context.go('/retos/$retoId');
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      _aviso('No se pudo crear el reto: $e');
    }
  }

  void _aviso(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return FeatureScaffold(
      title: 'Nuevo reto',
      backPath: '/retos',
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                _buildTituloCard(),
                const SizedBox(height: 20),
                const _SectionHeader(
                    icon: Icons.tune_rounded, label: 'Detalles'),
                const SizedBox(height: 8),
                _buildDetallesCard(),
                const SizedBox(height: 20),
                const _SectionHeader(
                    icon: Icons.event_rounded, label: 'Fechas'),
                const SizedBox(height: 8),
                _buildFechasCard(),
                const SizedBox(height: 20),
                const _SectionHeader(
                    icon: Icons.visibility_outlined, label: 'Visibilidad'),
                const SizedBox(height: 8),
                _buildVisibilidadCard(),
                const SizedBox(height: 20),
                const _SectionHeader(
                    icon: Icons.checklist_rounded,
                    label: 'Tareas',
                    trailing: 'Opcional'),
                const SizedBox(height: 8),
                _buildTareasCard(),
              ],
            ),
          ),
          _BarraCrear(
            habilitado: _tituloValido && !_guardando,
            guardando: _guardando,
            onCrear: _crearReto,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Secciones
  // ---------------------------------------------------------------------------
  Widget _buildTituloCard() {
    return _Card(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
      child: TextField(
        controller: _tituloCtrl,
        textCapitalization: TextCapitalization.sentences,
        maxLength: 80,
        style: const TextStyle(
          color: SVColors.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          height: 1.3,
        ),
        cursorColor: SVColors.secondary,
        onChanged: (_) => setState(() {}),
        decoration: const InputDecoration(
          hintText: '¿Qué quieres conseguir?',
          hintStyle: TextStyle(color: SVColors.onSurfaceMuted, fontSize: 18),
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          counterStyle: TextStyle(color: SVColors.onSurfaceMuted, fontSize: 11),
        ),
      ),
    );
  }

  Widget _buildDetallesCard() {
    return _Card(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          _OpcionFila(
            icon: Icons.label_outline,
            label: 'Asignatura',
            child: _ChipOpcion(
              icon: Icons.label_outline,
              label: _asignaturaNombre ?? 'Sin asignatura',
              color: _asignaturaId != null
                  ? _colorAsignatura(_asignaturaId!)
                  : null,
              activo: _asignaturaId != null,
              bloqueado: _asignaturaFija,
              onTap: _asignaturaFija ? null : _seleccionarAsignaturaReto,
            ),
          ),
          const Divider(height: 1),
          _OpcionFila(
            icon: Icons.local_fire_department_rounded,
            label: 'Esfuerzo',
            child: _EsfuerzoSelector(
              dificultad: _dificultad,
              onSeleccion: (d) => setState(() => _dificultad = d),
            ),
          ),
          const Divider(height: 1),
          _OpcionFila(
            icon: Icons.link_rounded,
            label: 'Vincular',
            child: _ChipOpcion(
              icon: Icons.link_rounded,
              label: _entidadVincTitulo ?? 'Examen o entrega',
              color: const Color(0xFF06B6D4),
              activo: _entidadVincId != null,
              onTap: _seleccionarEntidad,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFechasCard() {
    return _Card(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: _BotonFecha(
              icon: Icons.play_circle_outline,
              label: 'Inicio',
              fecha: _fechaInicio,
              onTap: () => _seleccionarFecha(inicio: true),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.arrow_forward_rounded,
                size: 16, color: SVColors.onSurfaceMuted),
          ),
          Expanded(
            child: _BotonFecha(
              icon: Icons.flag_outlined,
              label: 'Fin',
              fecha: _fechaFin,
              onTap: () => _seleccionarFecha(inicio: false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisibilidadCard() {
    return _Card(
      padding: const EdgeInsets.all(6),
      child: Row(
        children: [
          _OpcionVisibilidad(
            icon: Icons.lock_outline,
            label: 'Privado',
            sel: _visibilidad == 'private',
            onTap: () => setState(() => _visibilidad = 'private'),
          ),
          _OpcionVisibilidad(
            icon: Icons.group_outlined,
            label: 'Amigos',
            sel: _visibilidad == 'friends',
            onTap: () => setState(() => _visibilidad = 'friends'),
          ),
          _OpcionVisibilidad(
            icon: Icons.public_rounded,
            label: 'Público',
            sel: _visibilidad == 'public',
            onTap: () => setState(() => _visibilidad = 'public'),
          ),
        ],
      ),
    );
  }

  Widget _buildTareasCard() {
    return _Card(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_tareas.isEmpty)
            _TareasVacio(
              onAgregar: _agregarTarea,
            )
          else
            ..._tareas.asMap().entries.map((entry) {
              final i = entry.key;
              final t = entry.value;
              return _TareaRow(
                key: ValueKey(t.key),
                index: i,
                tarea: t,
                asignaturaRetoNombre: _asignaturaNombre,
                asignaturaRetoId: _asignaturaId,
                onChanged: () => setState(() {}),
                onDificultad: () => _ciclarDificultadTarea(i),
                onAsignatura: () => _seleccionarAsignaturaTarea(i),
                onAdjuntar: () => _adjuntarTarea(i),
                onQuitarAdjunto: () => _quitarAdjuntoTarea(i),
                onEliminar: () => _eliminarTarea(i),
              );
            }),
          if (_tareas.isNotEmpty) ...[
            const SizedBox(height: 10),
            _BotonAgregarTarea(
              texto: _tareas.length >= _maxTareas
                  ? 'Máximo $_maxTareas tareas'
                  : 'Añadir tarea',
              habilitado: _tareas.length < _maxTareas,
              onTap: _agregarTarea,
            ),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// Modelo de borrador de tarea
// =============================================================================
class _TareaDraft {
  _TareaDraft()
      : key = UniqueKey(),
        controller = TextEditingController(),
        focusNode = FocusNode();

  final UniqueKey key;
  final TextEditingController controller;
  final FocusNode focusNode;
  String dificultad = 'media';
  String? asignaturaId;
  String? asignaturaNombre;
  String? apunteId;
  String? apunteTitulo;
  String? archivoId;
  String? archivoNombre;

  String get titulo => controller.text.trim();

  bool get tieneAdjunto => apunteId != null || archivoId != null;

  void dispose() {
    controller.dispose();
    focusNode.dispose();
  }
}

// =============================================================================
// Barra inferior de creación (fija, nunca tapada por el teclado)
// =============================================================================
class _BarraCrear extends StatelessWidget {
  const _BarraCrear({
    required this.habilitado,
    required this.guardando,
    required this.onCrear,
  });

  final bool habilitado;
  final bool guardando;
  final VoidCallback onCrear;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: SVColors.surfaceContainerLowest,
        border: Border(
          top: BorderSide(color: SVColors.surfaceContainerHighest),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: SafeArea(
        top: false,
        child: FilledButton.icon(
          onPressed: habilitado ? onCrear : null,
          icon: guardando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.flag_rounded, size: 20),
          label: Text(
            guardando ? 'Creando…' : 'Crear reto',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: SVColors.secondary,
            foregroundColor: SVColors.onSecondary,
            disabledBackgroundColor: SVColors.surfaceContainerHighest,
            disabledForegroundColor: SVColors.onSurfaceMuted,
            minimumSize: const Size.fromHeight(52),
            shape:
                const RoundedRectangleBorder(borderRadius: SVShapes.standard12),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Componentes CLEAN UI
// =============================================================================
class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding = const EdgeInsets.all(14)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: const BoxDecoration(
        color: SVColors.surfaceContainerLowest,
        borderRadius: SVShapes.large16,
        boxShadow: _sombraSuave,
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.label,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: SVColors.secondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: SVColors.onSurface,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
          const Spacer(),
          if (trailing != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: const BoxDecoration(
                color: SVColors.surfaceContainerLow,
                borderRadius: SVShapes.pill,
              ),
              child: Text(
                trailing!,
                style: const TextStyle(
                  color: SVColors.onSurfaceMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _OpcionFila extends StatelessWidget {
  const _OpcionFila({
    required this.icon,
    required this.label,
    required this.child,
  });

  final IconData icon;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: SVColors.onSurfaceMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: SVColors.onSurface,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _ChipOpcion extends StatelessWidget {
  const _ChipOpcion({
    required this.icon,
    required this.label,
    required this.activo,
    required this.onTap,
    this.color,
    this.bloqueado = false,
  });

  final IconData icon;
  final String label;
  final bool activo;
  final Color? color;
  final VoidCallback? onTap;
  final bool bloqueado;

  @override
  Widget build(BuildContext context) {
    final c = color ?? SVColors.secondary;
    final fg = activo ? c : SVColors.onSurfaceMuted;
    return Material(
      color: activo ? c.withValues(alpha: 0.12) : SVColors.surfaceContainerLow,
      borderRadius: SVShapes.pill,
      child: InkWell(
        onTap: bloqueado ? null : onTap,
        borderRadius: SVShapes.pill,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 170),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 15, color: fg),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: fg, fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ),
                if (bloqueado) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.lock,
                      size: 12, color: SVColors.onSurfaceMuted),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EsfuerzoSelector extends StatelessWidget {
  const _EsfuerzoSelector({
    required this.dificultad,
    required this.onSeleccion,
  });

  final String dificultad;
  final ValueChanged<String> onSeleccion;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final d in ['baja', 'media', 'alta']) ...[
          _PildoraEsfuerzo(
            dificultad: d,
            seleccionada: dificultad == d,
            onTap: () => onSeleccion(d),
          ),
          if (d != 'alta') const SizedBox(width: 6),
        ],
      ],
    );
  }
}

class _PildoraEsfuerzo extends StatelessWidget {
  const _PildoraEsfuerzo({
    required this.dificultad,
    required this.seleccionada,
    required this.onTap,
  });

  final String dificultad;
  final bool seleccionada;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = _difColor(dificultad);
    return Material(
      color: seleccionada
          ? c.withValues(alpha: 0.14)
          : SVColors.surfaceContainerLow,
      borderRadius: SVShapes.pill,
      child: InkWell(
        onTap: onTap,
        borderRadius: SVShapes.pill,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Text(
            etiquetaEsfuerzo(dificultad),
            style: TextStyle(
              color: seleccionada ? c : SVColors.onSurfaceMuted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _BotonFecha extends StatelessWidget {
  const _BotonFecha({
    required this.icon,
    required this.label,
    required this.fecha,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final DateTime fecha;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final d = fecha.day.toString().padLeft(2, '0');
    final m = fecha.month.toString().padLeft(2, '0');
    return Material(
      color: SVColors.surfaceContainerLow,
      borderRadius: SVShapes.standard12,
      child: InkWell(
        onTap: onTap,
        borderRadius: SVShapes.standard12,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 16, color: SVColors.secondary),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          color: SVColors.onSurfaceMuted, fontSize: 10)),
                  Text('$d/$m/${fecha.year}',
                      style: const TextStyle(
                          color: SVColors.onSurface,
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OpcionVisibilidad extends StatelessWidget {
  const _OpcionVisibilidad({
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
            : Colors.transparent,
        borderRadius: SVShapes.standard12,
        child: InkWell(
          onTap: onTap,
          borderRadius: SVShapes.standard12,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              children: [
                Icon(icon, size: 18, color: fg),
                const SizedBox(height: 4),
                Text(label,
                    style: TextStyle(
                        color: fg, fontSize: 11, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TareasVacio extends StatelessWidget {
  const _TareasVacio({required this.onAgregar});

  final VoidCallback onAgregar;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: SVColors.secondary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.checklist_rounded,
              size: 22, color: SVColors.secondary),
        ),
        const SizedBox(height: 10),
        const Text(
          '¿Quieres dividirlo en pasos?',
          style: TextStyle(
            color: SVColors.onSurface,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Puedes crear el reto tal cual o añadir tareas para seguir tu progreso paso a paso.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: SVColors.onSurfaceMuted,
            fontSize: 12,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        _BotonAgregarTarea(texto: 'Añadir tarea', onTap: onAgregar),
      ],
    );
  }
}

class _BotonAgregarTarea extends StatelessWidget {
  const _BotonAgregarTarea({
    required this.texto,
    required this.onTap,
    this.habilitado = true,
  });

  final String texto;
  final VoidCallback onTap;
  final bool habilitado;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: habilitado
            ? SVColors.secondary.withValues(alpha: 0.08)
            : SVColors.surfaceContainerLow,
        borderRadius: SVShapes.pill,
        child: InkWell(
          onTap: habilitado ? onTap : null,
          borderRadius: SVShapes.pill,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add_rounded,
                  size: 16,
                  color:
                      habilitado ? SVColors.secondary : SVColors.onSurfaceMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  texto,
                  style: TextStyle(
                    color: habilitado
                        ? SVColors.secondary
                        : SVColors.onSurfaceMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TareaRow extends StatelessWidget {
  const _TareaRow({
    required this.index,
    required this.tarea,
    required this.asignaturaRetoNombre,
    required this.asignaturaRetoId,
    required this.onChanged,
    required this.onDificultad,
    required this.onAsignatura,
    required this.onAdjuntar,
    required this.onQuitarAdjunto,
    required this.onEliminar,
    super.key,
  });

  final int index;
  final _TareaDraft tarea;
  final String? asignaturaRetoNombre;
  final String? asignaturaRetoId;
  final VoidCallback onChanged;
  final VoidCallback onDificultad;
  final VoidCallback onAsignatura;
  final VoidCallback onAdjuntar;
  final VoidCallback onQuitarAdjunto;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    // Herencia visual: si la tarea no tiene asignatura propia, muestra la del
    // reto (heredada). El id usado para el color sigue esa misma lógica.
    final asigNombre = tarea.asignaturaNombre ?? asignaturaRetoNombre;
    final asigIdColor = tarea.asignaturaId ?? asignaturaRetoId;
    final heredada = tarea.asignaturaId == null && asignaturaRetoId != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 4, 6, 10),
      decoration: const BoxDecoration(
        color: SVColors.surfaceContainerLow,
        borderRadius: SVShapes.standard12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: SVColors.secondary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: SVColors.secondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: tarea.controller,
                  focusNode: tarea.focusNode,
                  style: const TextStyle(
                      color: SVColors.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w600),
                  cursorColor: SVColors.secondary,
                  textCapitalization: TextCapitalization.sentences,
                  maxLength: 80,
                  onChanged: (_) => onChanged(),
                  decoration: const InputDecoration(
                    isDense: true,
                    filled: false,
                    counterText: '',
                    hintText: 'Describe la tarea…',
                    hintStyle: TextStyle(color: SVColors.onSurfaceMuted),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
              IconButton(
                onPressed: onAdjuntar,
                icon: Icon(Icons.attach_file_rounded,
                    size: 18,
                    color: tarea.tieneAdjunto
                        ? SVColors.secondary
                        : SVColors.onSurfaceMuted),
                visualDensity: VisualDensity.compact,
                tooltip: 'Adjuntar apunte o archivo',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              IconButton(
                onPressed: onEliminar,
                icon: const Icon(Icons.close_rounded,
                    size: 18, color: SVColors.onSurfaceMuted),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 34, top: 2),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _MiniChipDificultad(
                  dificultad: tarea.dificultad,
                  onTap: onDificultad,
                ),
                if (asigNombre != null)
                  _MiniChipAsignatura(
                    nombre: asigNombre,
                    colorKey: asigIdColor ?? asigNombre,
                    heredada: heredada,
                    onTap: onAsignatura,
                  )
                else
                  _MiniChipEtiqueta(
                    icon: Icons.label_outline,
                    label: 'Asignatura',
                    onTap: onAsignatura,
                  ),
                if (tarea.tieneAdjunto)
                  _ChipAdjunto(
                    esApunte: tarea.apunteId != null,
                    nombre:
                        tarea.apunteTitulo ?? tarea.archivoNombre ?? 'Adjunto',
                    onQuitar: onQuitarAdjunto,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniChipDificultad extends StatelessWidget {
  const _MiniChipDificultad({required this.dificultad, required this.onTap});

  final String dificultad;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = _difColor(dificultad);
    return _MiniChipBase(
      color: c,
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department_rounded, size: 13, color: c),
          const SizedBox(width: 4),
          Text(etiquetaEsfuerzo(dificultad),
              style: TextStyle(
                  color: c, fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _MiniChipAsignatura extends StatelessWidget {
  const _MiniChipAsignatura({
    required this.nombre,
    required this.colorKey,
    required this.heredada,
    required this.onTap,
  });

  final String nombre;
  final String colorKey;
  final bool heredada;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = _colorAsignatura(colorKey);
    return _MiniChipBase(
      color: c,
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(heredada ? Icons.subdirectory_arrow_right : Icons.label_outline,
              size: 13, color: c),
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 140),
            child: Text(nombre,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: c, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _MiniChipEtiqueta extends StatelessWidget {
  const _MiniChipEtiqueta({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _MiniChipBase(
      color: SVColors.onSurfaceMuted,
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: SVColors.onSurfaceMuted),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  color: SVColors.onSurfaceMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _MiniChipBase extends StatelessWidget {
  const _MiniChipBase({
    required this.color,
    required this.child,
    required this.onTap,
  });

  final Color color;
  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.12),
      borderRadius: SVShapes.pill,
      child: InkWell(
        onTap: onTap,
        borderRadius: SVShapes.pill,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: child,
        ),
      ),
    );
  }
}

/// Chip del adjunto académico de una tarea (apunte o archivo) con quitar.
class _ChipAdjunto extends StatelessWidget {
  const _ChipAdjunto({
    required this.esApunte,
    required this.nombre,
    required this.onQuitar,
  });

  final bool esApunte;
  final String nombre;
  final VoidCallback onQuitar;

  @override
  Widget build(BuildContext context) {
    final c = esApunte ? const Color(0xFF3B82F6) : const Color(0xFF7C4DFF);
    final icon =
        esApunte ? Icons.description_outlined : Icons.attach_file_rounded;
    return Material(
      color: c.withValues(alpha: 0.1),
      borderRadius: SVShapes.pill,
      child: Padding(
        padding: const EdgeInsets.only(left: 10, right: 2, top: 3, bottom: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: c),
            const SizedBox(width: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 130),
              child: Text(
                esApunte ? 'Apunte · $nombre' : 'Archivo · $nombre',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: c, fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
            InkWell(
              onTap: onQuitar,
              customBorder: const CircleBorder(),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.close_rounded,
                    size: 13, color: c.withValues(alpha: 0.7)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
