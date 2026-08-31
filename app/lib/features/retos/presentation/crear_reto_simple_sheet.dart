import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/design_system/sv_colors.dart';
import '../../../core/design_system/sv_shapes.dart';
import '../../../shared/models/db_models.dart';
import '../../academico/application/asignaturas_provider.dart';
import '../application/retos_provider.dart';

/// Creación express de un reto en un Modal Inferior.
///
/// Un único flujo para todos los retos: desde aquí se puede crear el reto
/// directamente o saltar al editor completo con «Añadir tareas». El usuario
/// nunca ve la distinción simple/complejo.
///
/// Widget REUTILIZABLE: devuelve el `RetoDb` creado (útil para vincularlo a
/// otros flujos, p. ej. bloques del lienzo) y acepta [prefilledTitle],
/// [prefilledSubjectId] y [prefilledSubjectName] para acoplarse al contexto.
///
/// Si se pasa [retoId] el modal entra en modo edición y precarga los datos del
/// reto para actualizarlo en lugar de crear uno nuevo (devuelve null).
Future<RetoDb?> mostrarCrearRetoSimpleSheet(
  BuildContext context, {
  String? retoId,
  String? prefilledTitle,
  String? prefilledSubjectId,
  String? prefilledSubjectName,
}) {
  return showModalBottomSheet<RetoDb?>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: SVColors.surfaceContainerLowest,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _CrearRetoSimpleSheet(
      retoId: retoId,
      prefilledTitle: prefilledTitle,
      prefilledSubjectId: prefilledSubjectId,
      prefilledSubjectName: prefilledSubjectName,
    ),
  );
}

Color _difColor(String d) => switch (d) {
      'baja' => const Color(0xFF10B981),
      'alta' => const Color(0xFFEF4444),
      _ => const Color(0xFFF59E0B),
    };

class _CrearRetoSimpleSheet extends ConsumerStatefulWidget {
  const _CrearRetoSimpleSheet({
    this.retoId,
    this.prefilledTitle,
    this.prefilledSubjectId,
    this.prefilledSubjectName,
  });

  final String? retoId;
  final String? prefilledTitle;
  final String? prefilledSubjectId;
  final String? prefilledSubjectName;

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
    if (_esEdicion) {
      _cargarRetoEditar();
    } else {
      // Pre-llenado desde el contexto (título y asignatura preseleccionada).
      if (widget.prefilledTitle != null) {
        _tituloCtrl.text = widget.prefilledTitle!;
      }
      if (widget.prefilledSubjectId != null) {
        _asignaturaId = widget.prefilledSubjectId;
        _asignaturaNombre = widget.prefilledSubjectName;
      }
    }
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
    // Esperamos a que el provider resuelva para que la lista aparezca al
    // primer clic (antes el future aún no había cargado).
    final asignaturas = await ref.read(asignaturasActivasProvider.future);
    if (!mounted) return;
    final result = await showModalBottomSheet<AsignaturaDb?>(
      context: context,
      backgroundColor: SVColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
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
                onTap: () => Navigator.pop(ctx, null),
              ),
              if (asignaturas.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No tienes asignaturas activas.',
                      style: TextStyle(color: SVColors.onSurfaceMuted)),
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

  /// Salta al editor completo conservando el título y la asignatura elegidos.
  void _abrirEditorCompleto() {
    Navigator.pop(context);
    context.push('/retos/crear', extra: {
      'prefilledTitle': _tituloCtrl.text.trim(),
      if (_asignaturaId != null) 'prefilledSubjectId': _asignaturaId,
      if (_asignaturaNombre != null) 'prefilledSubjectName': _asignaturaNombre,
    });
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
        final data = await client
            .from('retos')
            .insert({
              'usuario_id': user.id,
              'titulo': titulo,
              'tipo': _asignaturaId != null ? 'academic' : 'fitness',
              'meta': titulo,
              'visibilidad': 'private',
              'dificultad': _dificultad,
              if (_asignaturaId != null) 'asignatura_id': _asignaturaId,
              'fecha_inicio': fechaInicio.toIso8601String(),
              'fecha_fin': fechaFin.toIso8601String(),
            })
            .select()
            .single();

        ref.invalidate(retosProvider);
        ref.invalidate(todosRetosProvider);

        if (!mounted) return;
        // Devolvemos el reto creado para que el llamador pueda vincularlo.
        Navigator.pop(context, RetoDb.fromMap(data));
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Reto creado'),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        return;
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
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
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
                  color: SVColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _esEdicion ? 'Editar reto' : 'Nuevo reto',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: SVColors.onSurface,
                    ),
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
            const SizedBox(height: 10),
            // Campo de título sin bordes
            TextField(
              controller: _tituloCtrl,
              autofocus: !_esEdicion,
              textCapitalization: TextCapitalization.sentences,
              maxLength: 80,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: SVColors.onSurface),
              cursorColor: SVColors.secondary,
              decoration: const InputDecoration(
                filled: false,
                hintText: '¿Qué reto quieres cumplir?',
                hintStyle: TextStyle(color: SVColors.onSurfaceMuted),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                counterStyle:
                    TextStyle(color: SVColors.onSurfaceMuted, fontSize: 11),
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _crear(),
            ),
            const SizedBox(height: 10),
            // Chips rápidos
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _QuickChip(
                  icon: Icons.label_outline,
                  label: _asignaturaNombre ?? 'Asignatura',
                  activo: _asignaturaId != null,
                  color: SVColors.secondary,
                  onTap: _seleccionarAsignatura,
                ),
                _QuickChip(
                  icon: Icons.local_fire_department_rounded,
                  label: etiquetaEsfuerzo(_dificultad),
                  activo: true,
                  color: _difColor(_dificultad),
                  onTap: _ciclarDificultad,
                ),
                _QuickChip(
                  icon: Icons.event_outlined,
                  label: _fechaLabel(),
                  activo: !_esHoy(_fecha),
                  color: SVColors.secondary,
                  onTap: _seleccionarFecha,
                ),
              ],
            ),
            const SizedBox(height: 18),
            // CTA principal a ancho completo
            FilledButton.icon(
              onPressed: _tituloValido && !_guardando ? _crear : null,
              icon: _guardando
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Icon(_esEdicion ? Icons.save_rounded : Icons.flag_rounded,
                      size: 18),
              label: Text(
                _guardando
                    ? (_esEdicion ? 'Guardando…' : 'Creando…')
                    : (_esEdicion ? 'Guardar cambios' : 'Crear reto'),
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: SVColors.secondary,
                foregroundColor: SVColors.onSecondary,
                disabledBackgroundColor: SVColors.surfaceContainerHighest,
                disabledForegroundColor: SVColors.onSurfaceMuted,
                minimumSize: const Size.fromHeight(50),
                shape: const RoundedRectangleBorder(
                    borderRadius: SVShapes.standard12),
              ),
            ),
            if (!_esEdicion) ...[
              const SizedBox(height: 6),
              Center(
                child: TextButton.icon(
                  onPressed: _abrirEditorCompleto,
                  icon: const Icon(Icons.checklist_rtl_rounded, size: 16),
                  label: const Text('Añadir tareas'),
                  style: TextButton.styleFrom(
                    foregroundColor: SVColors.primary,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ),
            ],
          ],
        ),
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
    final fg = activo ? color : SVColors.onSurfaceMuted;
    return Material(
      color:
          activo ? color.withValues(alpha: 0.12) : SVColors.surfaceContainerLow,
      borderRadius: SVShapes.pill,
      child: InkWell(
        onTap: onTap,
        borderRadius: SVShapes.pill,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 160),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                      fontWeight: FontWeight.w700,
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
