import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/db_models.dart';
import '../../../shared/widgets/feature_scaffold.dart';
import '../../academico/application/asignaturas_provider.dart';
import '../../academico/application/entregas_examenes_provider.dart';
import '../application/retos_provider.dart';

// =============================================================================
// Paleta y helpers (Flat / Clean UI sobre fondo #1A1A2E)
// =============================================================================
const _kFondo = Color(0xFF1A1A2E);
const _kCampo = Color(0x14FFFFFF); // blanco 8%
const _kTexto = Colors.white;
const _kTextoTenue = Color(0xB3FFFFFF); // blanco 70%

const _difLabels = {'baja': 'Baja', 'media': 'Media', 'alta': 'Alta'};
Color _difColor(String d) => switch (d) {
      'baja' => const Color(0xFF10B981),
      'alta' => const Color(0xFFEF4444),
      _ => const Color(0xFFF59E0B),
    };
String _difCiclo(String d) => switch (d) {
      'baja' => 'media',
      'media' => 'alta',
      _ => 'baja',
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

/// Pantalla de creación de retos con tareas (flujo Complejo).
class CrearRetoScreen extends ConsumerStatefulWidget {
  const CrearRetoScreen({this.prefilledSubjectId, super.key});

  final String? prefilledSubjectId;

  @override
  ConsumerState<CrearRetoScreen> createState() => _CrearRetoScreenState();
}

class _CrearRetoScreenState extends ConsumerState<CrearRetoScreen> {
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

  final List<_TareaDraft> _tareas = [
    _TareaDraft(titulo: ''),
    _TareaDraft(titulo: ''),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.prefilledSubjectId != null) {
      _asignaturaId = widget.prefilledSubjectId;
      _asignaturaFija = true;
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
    if (_tareas.length >= 12) return;
    setState(() => _tareas.add(_TareaDraft(titulo: '')));
  }

  void _eliminarTarea(int index) {
    if (_tareas.length <= 1) return;
    setState(() {
      _tareas[index].controller.dispose();
      _tareas.removeAt(index);
    });
  }

  Future<(String, String)?> _pickAsignatura() async {
    final asignaturas =
        ref.read(asignaturasActivasProvider).valueOrNull ?? const [];
    return showModalBottomSheet<(String, String)?>(
      context: context,
      backgroundColor: _kFondo,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            ListTile(
              leading: const Icon(Icons.block, size: 20, color: _kTextoTenue),
              title: const Text('Sin asignatura',
                  style: TextStyle(color: _kTexto)),
              onTap: () => Navigator.pop(ctx, ('', '')),
            ),
            if (asignaturas.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('No tienes asignaturas activas.',
                    style: TextStyle(color: _kTextoTenue)),
              )
            else
              ...asignaturas.map((AsignaturaDb a) => ListTile(
                    leading: Icon(Icons.label_outline,
                        size: 20, color: _colorAsignatura(a.id)),
                    title:
                        Text(a.nombre, style: const TextStyle(color: _kTexto)),
                    onTap: () => Navigator.pop(ctx, (a.id, a.nombre)),
                  )),
          ],
        ),
      ),
    );
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

  Future<void> _seleccionarEntidad() async {
    final entregas = ref.read(entregasPendientesProvider).valueOrNull ??
        const <EntregaExamenDb>[];
    final result = await showModalBottomSheet<EntregaExamenDb?>(
      context: context,
      backgroundColor: _kFondo,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text('Vincular a examen o entrega',
                  style:
                      TextStyle(color: _kTexto, fontWeight: FontWeight.w700)),
            ),
            ListTile(
              leading: const Icon(Icons.link_off_rounded,
                  size: 20, color: _kTextoTenue),
              title:
                  const Text('Sin vincular', style: TextStyle(color: _kTexto)),
              onTap: () => Navigator.pop(ctx, null),
            ),
            if (entregas.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('No tienes exámenes ni entregas pendientes.',
                    style: TextStyle(color: _kTextoTenue)),
              )
            else
              ...entregas.map((e) => ListTile(
                    leading: Icon(
                        e.tipo == 'examen'
                            ? Icons.quiz_outlined
                            : Icons.assignment_outlined,
                        size: 20,
                        color: const Color(0xFF06B6D4)),
                    title:
                        Text(e.titulo, style: const TextStyle(color: _kTexto)),
                    subtitle: Text(
                      '${e.tipo == 'examen' ? 'Examen' : 'Entrega'} · ${e.fechaLimite.day}/${e.fechaLimite.month}',
                      style: const TextStyle(color: _kTextoTenue, fontSize: 11),
                    ),
                    onTap: () => Navigator.pop(ctx, e),
                  )),
          ],
        ),
      ),
    );
    if (!mounted) return;
    setState(() {
      if (result == null) {
        _entidadVincId = null;
        _entidadVincTipo = null;
        _entidadVincTitulo = null;
      } else {
        _entidadVincId = result.id;
        _entidadVincTipo = result.tipo == 'examen' ? 'examen' : 'entrega';
        _entidadVincTitulo = result.titulo;
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

  Future<void> _crearReto() async {
    if (_guardando) return;
    final titulo = _tituloCtrl.text.trim();
    if (titulo.length < 5) {
      _aviso('El título debe tener al menos 5 caracteres.');
      return;
    }
    final tareasValidas = _tareas.where((t) => t.titulo.length >= 3).toList();
    if (tareasValidas.isEmpty) {
      _aviso('Añade al menos una tarea (mínimo 3 caracteres).');
      return;
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
        });
      }
      await client.from('hitos_de_reto').insert(hitos);

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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return FeatureScaffold(
      title: 'Reto con tareas',
      backPath: '/retos',
      child: ColoredBox(
        color: _kFondo,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            // Título del reto (campo plano)
            TextField(
              controller: _tituloCtrl,
              textCapitalization: TextCapitalization.sentences,
              maxLength: 80,
              style: const TextStyle(
                  color: _kTexto, fontSize: 20, fontWeight: FontWeight.w700),
              cursorColor: Colors.white,
              decoration: const InputDecoration(
                hintText: 'Nombre del reto…',
                hintStyle: TextStyle(color: Color(0x66FFFFFF), fontSize: 20),
                border: InputBorder.none,
                counterStyle: TextStyle(color: _kTextoTenue),
              ),
            ),
            const SizedBox(height: 8),

            // Asignatura del reto + Dificultad
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ChipPlano(
                  icon: Icons.label_outline,
                  label: _asignaturaNombre ?? 'Asignatura',
                  color: _asignaturaId != null
                      ? _colorAsignatura(_asignaturaId!)
                      : null,
                  activo: _asignaturaId != null,
                  bloqueado: _asignaturaFija,
                  onTap: _asignaturaFija ? null : _seleccionarAsignaturaReto,
                ),
                _ChipDificultad(
                  dificultad: _dificultad,
                  onTap: () =>
                      setState(() => _dificultad = _difCiclo(_dificultad)),
                ),
                _ChipPlano(
                  icon: Icons.link_rounded,
                  label: _entidadVincTitulo ?? 'Vincular',
                  color: const Color(0xFF06B6D4),
                  activo: _entidadVincId != null,
                  onTap: _seleccionarEntidad,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Fechas (planas)
            Row(
              children: [
                Expanded(
                  child: _BotonFecha(
                    label: 'Inicio',
                    fecha: _fechaInicio,
                    onTap: () => _seleccionarFecha(inicio: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _BotonFecha(
                    label: 'Fin',
                    fecha: _fechaFin,
                    onTap: () => _seleccionarFecha(inicio: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Visibilidad (chips planos)
            Wrap(
              spacing: 8,
              children: [
                _ChipVisibilidad(
                  label: 'Privado',
                  icon: Icons.lock_outline,
                  sel: _visibilidad == 'private',
                  onTap: () => setState(() => _visibilidad = 'private'),
                ),
                _ChipVisibilidad(
                  label: 'Amigos',
                  icon: Icons.group_outlined,
                  sel: _visibilidad == 'friends',
                  onTap: () => setState(() => _visibilidad = 'friends'),
                ),
                _ChipVisibilidad(
                  label: 'Público',
                  icon: Icons.public,
                  sel: _visibilidad == 'public',
                  onTap: () => setState(() => _visibilidad = 'public'),
                ),
              ],
            ),
            const SizedBox(height: 22),

            const Text('Tareas',
                style: TextStyle(
                    color: _kTexto, fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),

            // Lista de tareas (filas planas)
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
                onDificultad: () =>
                    setState(() => t.dificultad = _difCiclo(t.dificultad)),
                onAsignatura: () => _seleccionarAsignaturaTarea(i),
                onEliminar: _tareas.length > 1 ? () => _eliminarTarea(i) : null,
              );
            }),

            // Botón "Añadir tarea" plano, siempre al final
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _agregarTarea,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Añadir tarea'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF72FE8F),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _guardando ? null : _crearReto,
                icon: _guardando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.flag_rounded),
                label: Text(_guardando ? 'Creando…' : 'Crear reto'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF006E2D),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Modelo de borrador de tarea
// =============================================================================
class _TareaDraft {
  _TareaDraft({required String titulo})
      : key = UniqueKey(),
        controller = TextEditingController(text: titulo);

  final UniqueKey key;
  final TextEditingController controller;
  String dificultad = 'media';
  String? asignaturaId;
  String? asignaturaNombre;

  String get titulo => controller.text.trim();
}

// =============================================================================
// Fila de tarea (flat, con micro-chip de asignatura y selector de dificultad)
// =============================================================================
class _TareaRow extends StatelessWidget {
  const _TareaRow({
    required this.index,
    required this.tarea,
    required this.asignaturaRetoNombre,
    required this.asignaturaRetoId,
    required this.onChanged,
    required this.onDificultad,
    required this.onAsignatura,
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
  final VoidCallback? onEliminar;

  @override
  Widget build(BuildContext context) {
    // Herencia visual: si la tarea no tiene asignatura propia, muestra la del
    // reto (heredada). El id usado para el color sigue esa misma lógica.
    final asigNombre = tarea.asignaturaNombre ?? asignaturaRetoNombre;
    final asigIdColor = tarea.asignaturaId ?? asignaturaRetoId;
    final heredada = tarea.asignaturaId == null && asignaturaRetoId != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 6, 6, 10),
      decoration: BoxDecoration(
        color: _kCampo,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('${index + 1}.',
                  style: const TextStyle(
                      color: _kTextoTenue, fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: tarea.controller,
                  style: const TextStyle(color: _kTexto, fontSize: 14),
                  cursorColor: Colors.white,
                  textCapitalization: TextCapitalization.sentences,
                  maxLength: 80,
                  onChanged: (_) => onChanged(),
                  decoration: const InputDecoration(
                    isDense: true,
                    counterText: '',
                    hintText: 'Describe la tarea…',
                    hintStyle: TextStyle(color: Color(0x66FFFFFF)),
                    border: InputBorder.none,
                  ),
                ),
              ),
              if (onEliminar != null)
                IconButton(
                  onPressed: onEliminar,
                  icon: const Icon(Icons.close_rounded,
                      size: 18, color: Color(0x99FFFFFF)),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 22, top: 2),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _ChipDificultad(
                    dificultad: tarea.dificultad, onTap: onDificultad),
                if (asigNombre != null)
                  _MicroChipAsignatura(
                    nombre: asigNombre,
                    colorKey: asigIdColor ?? asigNombre,
                    heredada: heredada,
                    onTap: onAsignatura,
                  )
                else
                  _ChipPlano(
                    icon: Icons.label_outline,
                    label: 'Asignatura',
                    activo: false,
                    onTap: onAsignatura,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Componentes planos reutilizables
// =============================================================================
class _ChipPlano extends StatelessWidget {
  const _ChipPlano({
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
    final c = color ?? const Color(0xFF72FE8F);
    final fg = activo ? c : _kTextoTenue;
    return Material(
      color: activo ? c.withValues(alpha: 0.15) : _kCampo,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: bloqueado ? null : onTap,
        borderRadius: BorderRadius.circular(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 150),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 15, color: fg),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: fg, fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                ),
                if (bloqueado) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.lock, size: 12, color: _kTextoTenue),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChipDificultad extends StatelessWidget {
  const _ChipDificultad({required this.dificultad, required this.onTap});

  final String dificultad;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = _difColor(dificultad);
    final xp = xpPorDificultad(dificultad);
    return Material(
      color: c.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.local_fire_department_rounded, size: 15, color: c),
              const SizedBox(width: 5),
              Text('${_difLabels[dificultad]} · +$xp XP',
                  style: TextStyle(
                      color: c, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MicroChipAsignatura extends StatelessWidget {
  const _MicroChipAsignatura({
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
    return Material(
      color: c.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 160),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(heredada ? Icons.subdirectory_arrow_right : Icons.label,
                    size: 13, color: c),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: c, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChipVisibilidad extends StatelessWidget {
  const _ChipVisibilidad({
    required this.label,
    required this.icon,
    required this.sel,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool sel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF72FE8F);
    final fg = sel ? accent : _kTextoTenue;
    return Material(
      color: sel ? accent.withValues(alpha: 0.15) : _kCampo,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: fg),
              const SizedBox(width: 5),
              Text(label,
                  style: TextStyle(
                      color: fg, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _BotonFecha extends StatelessWidget {
  const _BotonFecha({
    required this.label,
    required this.fecha,
    required this.onTap,
  });

  final String label;
  final DateTime fecha;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final d = fecha.day.toString().padLeft(2, '0');
    final m = fecha.month.toString().padLeft(2, '0');
    return Material(
      color: _kCampo,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.event_outlined, size: 16, color: _kTextoTenue),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style:
                          const TextStyle(color: _kTextoTenue, fontSize: 10)),
                  Text('$d/$m/${fecha.year}',
                      style: const TextStyle(
                          color: _kTexto,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
