import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/db_models.dart';
import '../../academico/application/asignaturas_provider.dart';
import '../application/retos_provider.dart';

/// Creación express de un reto Simple en un Modal Inferior minimalista.
/// Un único campo de texto + iconos rápidos (asignatura · dificultad · fecha).
///
/// Si se pasa [retoId] el modal entra en modo edición y precarga los datos del
/// reto para actualizarlo en lugar de crear uno nuevo.
Future<void> mostrarCrearRetoSimpleSheet(BuildContext context,
    {String? retoId}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _CrearRetoSimpleSheet(retoId: retoId),
  );
}

const _difLabels = {'baja': 'Baja', 'media': 'Media', 'alta': 'Alta'};

Color _difColor(String d) => switch (d) {
      'baja' => const Color(0xFF10B981),
      'alta' => const Color(0xFFEF4444),
      _ => const Color(0xFFF59E0B),
    };

class _CrearRetoSimpleSheet extends ConsumerStatefulWidget {
  const _CrearRetoSimpleSheet({this.retoId});

  final String? retoId;

  @override
  ConsumerState<_CrearRetoSimpleSheet> createState() =>
      _CrearRetoSimpleSheetState();
}

class _CrearRetoSimpleSheetState extends ConsumerState<_CrearRetoSimpleSheet> {
  final _tituloCtrl = TextEditingController();
  String _dificultad = 'media';
  String? _asignaturaId;
  String? _asignaturaNombre;
  DateTime _fecha = DateTime.now();
  bool _guardando = false;
  bool _cargandoEdicion = false;

  bool get _esEdicion => widget.retoId != null;

  @override
  void initState() {
    super.initState();
    if (_esEdicion) _cargarRetoEditar();
  }

  Future<void> _cargarRetoEditar() async {
    setState(() => _cargandoEdicion = true);
    try {
      final client = Supabase.instance.client;
      final row = await client
          .from('retos')
          .select('titulo, dificultad, asignatura_id, fecha_fin, '
              'asignaturas(nombre)')
          .eq('id', widget.retoId!)
          .maybeSingle();
      if (row != null && mounted) {
        final asig = row['asignaturas'];
        setState(() {
          _tituloCtrl.text = row['titulo'] as String? ?? '';
          _dificultad = row['dificultad'] as String? ?? 'media';
          _asignaturaId = row['asignatura_id'] as String?;
          _asignaturaNombre = asig is Map ? asig['nombre'] as String? : null;
          final ff = row['fecha_fin'];
          if (ff != null) {
            final f = DateTime.parse(ff as String);
            _fecha = DateTime(f.year, f.month, f.day);
          }
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _cargandoEdicion = false);
    }
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    super.dispose();
  }

  bool get _tituloValido => _tituloCtrl.text.trim().length >= 5;

  bool _esHoy(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  String _fechaLabel() {
    if (_esHoy(_fecha)) return 'Hoy';
    return '${_fecha.day.toString().padLeft(2, '0')}/${_fecha.month.toString().padLeft(2, '0')}';
  }

  void _ciclarDificultad() {
    setState(() {
      _dificultad = switch (_dificultad) {
        'baja' => 'media',
        'media' => 'alta',
        _ => 'baja',
      };
    });
  }

  Future<void> _seleccionarAsignatura() async {
    final asignaturas =
        ref.read(asignaturasActivasProvider).valueOrNull ?? const [];
    final result = await showModalBottomSheet<AsignaturaDb?>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              ListTile(
                leading: const Icon(Icons.block, size: 20),
                title: const Text('Sin asignatura'),
                onTap: () => Navigator.pop(ctx, null),
              ),
              if (asignaturas.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No tienes asignaturas activas.',
                      style: TextStyle(color: Colors.grey)),
                )
              else
                ...asignaturas.map((a) => ListTile(
                      leading: const Icon(Icons.label_outline, size: 20),
                      title: Text(a.nombre),
                      selected: a.id == _asignaturaId,
                      onTap: () => Navigator.pop(ctx, a),
                    )),
            ],
          ),
        );
      },
    );
    // result == null puede significar "Sin asignatura" o cerrar; tratamos el
    // tap explícito en "Sin asignatura" reseteando.
    if (!mounted) return;
    setState(() {
      _asignaturaId = result?.id;
      _asignaturaNombre = result?.nombre;
    });
  }

  Future<void> _seleccionarFecha() async {
    final now = DateTime.now();
    final hoy = DateTime(now.year, now.month, now.day);
    final sel = await showDatePicker(
      context: context,
      initialDate: _fecha.isBefore(hoy) ? hoy : _fecha,
      firstDate: hoy,
      lastDate: DateTime(2100),
      helpText: 'Fecha límite del reto',
    );
    if (sel != null && mounted) {
      setState(() => _fecha = DateTime(sel.year, sel.month, sel.day));
    }
  }

  Future<void> _crear() async {
    if (_guardando || !_tituloValido) return;
    setState(() => _guardando = true);
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) throw Exception('Sesión no activa');

      final titulo = _tituloCtrl.text.trim();
      final now = DateTime.now();
      final fechaInicio = DateTime(now.year, now.month, now.day);
      // La fecha límite debe ser posterior al inicio (CHECK fecha_fin > inicio).
      final fechaFin = DateTime(_fecha.year, _fecha.month, _fecha.day, 23, 59);

      if (_esEdicion) {
        await editarRetoSimple(
          retoId: widget.retoId!,
          titulo: titulo,
          dificultad: _dificultad,
          asignaturaId: _asignaturaId,
          fechaFin: fechaFin,
          ref: ref,
        );
      } else {
        await client.from('retos').insert({
          'usuario_id': user.id,
          'titulo': titulo,
          'tipo': _asignaturaId != null ? 'academic' : 'fitness',
          'meta': titulo,
          'visibilidad': 'private',
          'dificultad': _dificultad,
          if (_asignaturaId != null) 'asignatura_id': _asignaturaId,
          'fecha_inicio': fechaInicio.toIso8601String(),
          'fecha_fin': fechaFin.toIso8601String(),
        });

        ref.invalidate(retosProvider);
        ref.invalidate(todosRetosProvider);
      }

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(_esEdicion ? 'Reto actualizado' : 'Reto creado'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'No se pudo ${_esEdicion ? "actualizar" : "crear"} el reto: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          if (_esEdicion) ...[
            Row(
              children: [
                Text(
                  'Editar reto',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                if (_cargandoEdicion) ...[
                  const SizedBox(width: 10),
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
          ],
          // Campo de texto sin bordes (express)
          TextField(
            controller: _tituloCtrl,
            autofocus: !_esEdicion,
            textCapitalization: TextCapitalization.sentences,
            maxLength: 80,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            decoration: const InputDecoration.collapsed(
              hintText: 'Escribe tu reto…',
            ),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _crear(),
          ),
          const SizedBox(height: 8),
          // Fila de iconos rápidos
          Row(
            children: [
              _QuickChip(
                icon: Icons.label_outline,
                label: _asignaturaNombre ?? 'Asignatura',
                activo: _asignaturaId != null,
                color: cs.primary,
                onTap: _seleccionarAsignatura,
              ),
              const SizedBox(width: 8),
              _QuickChip(
                icon: Icons.local_fire_department_rounded,
                label: _difLabels[_dificultad]!,
                activo: true,
                color: _difColor(_dificultad),
                onTap: _ciclarDificultad,
              ),
              const SizedBox(width: 8),
              _QuickChip(
                icon: Icons.event_outlined,
                label: _fechaLabel(),
                activo: !_esHoy(_fecha),
                color: cs.primary,
                onTap: _seleccionarFecha,
              ),
              const Spacer(),
              _BotonCrear(
                habilitado: _tituloValido && !_guardando,
                cargando: _guardando,
                onTap: _crear,
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (!_esEdicion)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/retos/crear');
                },
                icon: const Icon(Icons.checklist_rtl_rounded, size: 16),
                label: const Text('Crear reto con tareas'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({
    required this.icon,
    required this.label,
    required this.activo,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool activo;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fg = activo ? color : cs.onSurfaceVariant;
    return Material(
      color: activo ? color.withValues(alpha: 0.12) : cs.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 120),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: fg),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: fg,
                    ),
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

class _BotonCrear extends StatelessWidget {
  const _BotonCrear({
    required this.habilitado,
    required this.cargando,
    required this.onTap,
  });

  final bool habilitado;
  final bool cargando;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: habilitado ? cs.primary : cs.surfaceContainerHighest,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: habilitado ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: cargando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : Icon(
                  Icons.arrow_upward_rounded,
                  size: 18,
                  color: habilitado ? cs.onPrimary : cs.onSurfaceVariant,
                ),
        ),
      ),
    );
  }
}
