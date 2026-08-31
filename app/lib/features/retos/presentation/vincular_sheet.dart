import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/design_system/sv_colors.dart';
import '../../academico/application/entregas_examenes_provider.dart';

/// Entidad a la que se vincula un reto.
class Vinculo {
  const Vinculo({required this.id, required this.tipo, required this.titulo});

  /// Resultado especial que indica «quitar vinculación».
  const Vinculo.vacio()
      : id = '',
        tipo = '',
        titulo = '';

  final String id;
  final String tipo; // 'examen' | 'entrega' | 'bloque'
  final String titulo;

  bool get esVacio => id.isEmpty;
}

/// Abre el selector de vinculación de retos.
///
/// Muestra los exámenes/entregas pendientes del usuario (filtrados por la
/// asignatura del reto si la hay) y sus bloques de estudio futuros del
/// calendario. Devuelve `null` si el usuario cierra sin elegir.
Future<Vinculo?> mostrarVincularSheet(
  BuildContext context, {
  String? asignaturaId,
}) {
  return showModalBottomSheet<Vinculo?>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: SVColors.surfaceContainerLowest,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => VincularSheet(asignaturaId: asignaturaId),
  );
}

class VincularSheet extends ConsumerStatefulWidget {
  const VincularSheet({required this.asignaturaId, super.key});

  final String? asignaturaId;

  @override
  ConsumerState<VincularSheet> createState() => _VincularSheetState();
}

class _VincularSheetState extends ConsumerState<VincularSheet> {
  bool _cargando = true;
  List<_EntregaVinculable> _entregas = [];
  List<_BloqueVinculable> _bloques = [];

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

    // Entregas/exámenes pendientes. Esperamos al provider para evitar que el
    // primer clic muestre la lista vacía por carga asíncrona.
    List<_EntregaVinculable> entregas = [];
    try {
      final data = await ref.read(entregasPendientesProvider.future);
      var lista = data;
      // Si el reto tiene asignatura, priorizamos sus entregas.
      if (widget.asignaturaId != null) {
        final deLaAsignatura =
            lista.where((e) => e.asignaturaId == widget.asignaturaId).toList();
        if (deLaAsignatura.isNotEmpty) lista = deLaAsignatura;
      }
      entregas = lista
          .map((e) => _EntregaVinculable(
                id: e.id,
                tipo: e.tipo == 'examen' ? 'examen' : 'entrega',
                titulo: e.titulo,
                fechaLimite: e.fechaLimite,
              ))
          .toList();
    } catch (_) {
      entregas = [];
    }

    // Bloques de estudio futuros del calendario.
    List<_BloqueVinculable> bloques = [];
    try {
      final data = await client
          .from('horarios_academicos')
          .select('id, temas, hora_inicio, asignaturas(nombre)')
          .eq('usuario_id', user.id)
          .inFilter('tipo_actividad', ['estudio', 'repaso'])
          .gte('hora_inicio', DateTime.now().toIso8601String())
          .order('hora_inicio', ascending: true)
          .limit(50);
      bloques = (data as List).map((row) {
        final raw = row as Map<String, dynamic>;
        final asig = raw['asignaturas'];
        final asigNombre = asig is Map ? asig['nombre'] as String? : null;
        final horaInicio = DateTime.parse(raw['hora_inicio'] as String);
        return _BloqueVinculable(
          id: raw['id'] as String,
          titulo:
              (raw['temas'] as String?) ?? asigNombre ?? 'Bloque de estudio',
          asignaturaNombre: asigNombre,
          horaInicio: horaInicio,
        );
      }).toList();
    } catch (_) {
      bloques = [];
    }

    if (!mounted) return;
    setState(() {
      _entregas = entregas;
      _bloques = bloques;
      _cargando = false;
    });
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
              child: Text('Vincular reto',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: SVColors.onSurface)),
            ),
            const SizedBox(height: 4),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Ata el reto a un examen, una entrega o un bloque de estudio de tu calendario.',
                style: TextStyle(fontSize: 12, color: SVColors.onSurfaceMuted),
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: _cargando
                  ? const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      children: [
                        ListTile(
                          dense: true,
                          leading: const Icon(Icons.link_off_rounded,
                              size: 20, color: SVColors.onSurfaceMuted),
                          title: const Text('Sin vincular'),
                          onTap: () =>
                              Navigator.pop(context, const Vinculo.vacio()),
                        ),
                        const _SectionHeader(
                          icon: Icons.event_available_rounded,
                          label: 'Exámenes y entregas',
                        ),
                        if (_entregas.isEmpty)
                          const _Vacio(
                              'No tienes exámenes ni entregas pendientes.')
                        else
                          ..._entregas.map((e) => ListTile(
                                dense: true,
                                leading: Icon(
                                  e.tipo == 'examen'
                                      ? Icons.quiz_outlined
                                      : Icons.assignment_outlined,
                                  size: 20,
                                  color: const Color(0xFF06B6D4),
                                ),
                                title: Text(e.titulo,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 13)),
                                subtitle: Text(
                                  '${e.tipo == 'examen' ? 'Examen' : 'Entrega'} · ${e.fechaLimite.day}/${e.fechaLimite.month}',
                                  style: const TextStyle(
                                      color: SVColors.onSurfaceMuted,
                                      fontSize: 11),
                                ),
                                onTap: () => Navigator.pop(
                                  context,
                                  Vinculo(
                                    id: e.id,
                                    tipo: e.tipo,
                                    titulo: e.titulo,
                                  ),
                                ),
                              )),
                        const _SectionHeader(
                          icon: Icons.menu_book_rounded,
                          label: 'Bloques de estudio',
                        ),
                        if (_bloques.isEmpty)
                          const _Vacio(
                              'No tienes bloques de estudio futuros en el calendario.')
                        else
                          ..._bloques.map((b) => ListTile(
                                dense: true,
                                leading: const Icon(Icons.menu_book_rounded,
                                    size: 20, color: Color(0xFF3B82F6)),
                                title: Text(b.titulo,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 13)),
                                subtitle: Text(
                                  [
                                    if (b.asignaturaNombre != null)
                                      b.asignaturaNombre!,
                                    '${b.horaInicio.day}/${b.horaInicio.month} ${b.horaInicio.hour.toString().padLeft(2, '0')}:${b.horaInicio.minute.toString().padLeft(2, '0')}',
                                  ].join(' · '),
                                  style: const TextStyle(
                                      color: SVColors.onSurfaceMuted,
                                      fontSize: 11),
                                ),
                                onTap: () => Navigator.pop(
                                  context,
                                  Vinculo(
                                    id: b.id,
                                    tipo: 'bloque',
                                    titulo: b.titulo,
                                  ),
                                ),
                              )),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EntregaVinculable {
  const _EntregaVinculable({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.fechaLimite,
  });

  final String id;
  final String tipo;
  final String titulo;
  final DateTime fechaLimite;
}

class _BloqueVinculable {
  const _BloqueVinculable({
    required this.id,
    required this.titulo,
    required this.horaInicio,
    this.asignaturaNombre,
  });

  final String id;
  final String titulo;
  final DateTime horaInicio;
  final String? asignaturaNombre;
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: SVColors.secondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
              color: SVColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _Vacio extends StatelessWidget {
  const _Vacio(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
      child: Text(
        texto,
        style: const TextStyle(
            fontSize: 12, color: SVColors.onSurfaceMuted, height: 1.4),
      ),
    );
  }
}
