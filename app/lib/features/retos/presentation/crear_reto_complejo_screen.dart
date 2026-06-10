import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/widgets/feature_scaffold.dart';
import '../../../shared/widgets/sv_primary_button.dart';
import '../application/retos_provider.dart';

class CrearRetoComplejoScreen extends ConsumerStatefulWidget {
  const CrearRetoComplejoScreen({super.key});

  @override
  ConsumerState<CrearRetoComplejoScreen> createState() =>
      _CrearRetoComplejoScreenState();
}

class _CrearRetoComplejoScreenState
    extends ConsumerState<CrearRetoComplejoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _metaController = TextEditingController();

  String _tipo = 'fitness';
  String _visibilidad = 'private';
  DateTime _fechaInicio = DateTime.now();
  DateTime _fechaFin = DateTime.now().add(const Duration(days: 30));
  bool _guardando = false;

  final List<_TareaDraft> _tareas = [
    _TareaDraft(titulo: 'Primera tarea'),
    _TareaDraft(titulo: 'Segunda tarea'),
  ];

  @override
  void dispose() {
    _tituloController.dispose();
    _metaController.dispose();
    for (final t in _tareas) {
      t.controller.dispose();
    }
    super.dispose();
  }

  Future<void> _seleccionarFecha({required bool inicio}) async {
    final fechaBase = inicio ? _fechaInicio : _fechaFin;
    final fechaMin =
        inicio ? DateTime(2020) : _fechaInicio.add(const Duration(days: 1));

    final seleccion = await showDatePicker(
      context: context,
      initialDate: fechaBase.isBefore(fechaMin) ? fechaMin : fechaBase,
      firstDate: fechaMin,
      lastDate: DateTime(2100),
    );

    if (seleccion == null) return;

    setState(() {
      if (inicio) {
        _fechaInicio = DateTime(seleccion.year, seleccion.month, seleccion.day);
        if (!_fechaFin.isAfter(_fechaInicio)) {
          _fechaFin = _fechaInicio.add(const Duration(days: 1));
        }
      } else {
        _fechaFin = DateTime(seleccion.year, seleccion.month, seleccion.day);
      }
    });
  }

  void _agregarTarea() {
    if (_tareas.length >= 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Máximo 8 tareas por reto complejo.')),
      );
      return;
    }
    setState(() {
      _tareas.add(_TareaDraft(titulo: 'Tarea ${_tareas.length + 1}'));
    });
  }

  void _eliminarTarea(int index) {
    if (_tareas.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El reto debe tener al menos 1 tarea.')),
      );
      return;
    }
    setState(() {
      _tareas.removeAt(index);
    });
  }

  Future<void> _crearRetoComplejo() async {
    if (_guardando) return;
    if (!_formKey.currentState!.validate()) return;

    if (!_fechaFin.isAfter(_fechaInicio)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'La fecha de fin debe ser posterior a la fecha de inicio.')),
      );
      return;
    }

    if (_tareas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega al menos 1 tarea.')),
      );
      return;
    }

    for (var i = 0; i < _tareas.length; i++) {
      if (_tareas[i].titulo.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('La tarea ${i + 1} necesita un título.')),
        );
        return;
      }
    }

    setState(() => _guardando = true);

    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) {
        throw Exception(
            'No hay sesión activa. Inicia sesión para crear retos.');
      }

      final retoMap = await client
          .from('retos')
          .insert({
            'usuario_id': user.id,
            'titulo': _tituloController.text.trim(),
            'tipo': _tipo,
            'meta': _metaController.text.trim(),
            'visibilidad': _visibilidad,
            'fecha_inicio': _fechaInicio.toIso8601String(),
            'fecha_fin': _fechaFin.toIso8601String(),
          })
          .select('id')
          .single();

      final retoId = retoMap['id'] as String;

      // Peso automático: distribuido equitativamente
      final pesoPorTarea = 100.0 / _tareas.length;

      final tareasInsert = <Map<String, dynamic>>[];
      for (var i = 0; i < _tareas.length; i++) {
        final t = _tareas[i];
        tareasInsert.add({
          'reto_id': retoId,
          'titulo': t.titulo,
          'porcentaje_peso': double.parse(pesoPorTarea.toStringAsFixed(2)),
          'indice_orden': i + 1,
          'progreso_actual': 0,
          'esta_completado': false,
        });
      }

      await client.from('hitos_de_reto').insert(tareasInsert);

      ref.invalidate(retosProvider);

      if (mounted) {
        context.go('/retos/$retoId');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FeatureScaffold(
      title: 'Crear reto complejo',
      backPath: '/retos',
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _tituloController,
              decoration: const InputDecoration(
                labelText: 'Título del reto',
                hintText: 'ej: Preparar 5 exámenes',
              ),
              validator: (v) => (v == null || v.trim().length < 3)
                  ? 'Mínimo 3 caracteres'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _metaController,
              decoration: const InputDecoration(
                labelText: 'Meta',
                hintText: 'ej: Estudiar 50 horas',
              ),
              validator: (v) => (v == null || v.trim().length < 2)
                  ? 'Describe la meta'
                  : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _tipo,
                    decoration: const InputDecoration(labelText: 'Tipo'),
                    items: const [
                      DropdownMenuItem(
                          value: 'fitness', child: Text('Fitness')),
                      DropdownMenuItem(
                          value: 'academic', child: Text('Académico')),
                    ],
                    onChanged: (v) => setState(() => _tipo = v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _visibilidad,
                    decoration: const InputDecoration(labelText: 'Visibilidad'),
                    items: const [
                      DropdownMenuItem(
                          value: 'private', child: Text('Privado')),
                      DropdownMenuItem(value: 'public', child: Text('Público')),
                      DropdownMenuItem(
                          value: 'friends', child: Text('Solo amigos')),
                    ],
                    onChanged: (v) => setState(() => _visibilidad = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _DateButton(
                    label: 'Fecha inicio',
                    date: _fechaInicio,
                    onTap: () => _seleccionarFecha(inicio: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateButton(
                    label: 'Fecha fin',
                    date: _fechaFin,
                    onTap: () => _seleccionarFecha(inicio: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Text('Tareas', style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Añadir'),
                  onPressed: _agregarTarea,
                ),
              ],
            ),
            const SizedBox(height: 8),
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _tareas.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (oldIndex < newIndex) newIndex -= 1;
                  final item = _tareas.removeAt(oldIndex);
                  _tareas.insert(newIndex, item);
                });
              },
              itemBuilder: (context, index) {
                final t = _tareas[index];
                return Card(
                  key: ValueKey(t.key),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.drag_handle),
                    title: TextFormField(
                      controller: t.controller,
                      decoration: InputDecoration(
                        hintText: 'Tarea ${index + 1}',
                        border: InputBorder.none,
                        errorText: t.titulo.isEmpty ? 'Título requerido' : null,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _eliminarTarea(index),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            SVPrimaryButton(
              label: _guardando ? 'Guardando...' : 'Crear reto complejo',
              onPressed: _guardando ? null : _crearRetoComplejo,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _TareaDraft {
  _TareaDraft({required String titulo})
      : key = UniqueKey(),
        controller = TextEditingController(text: titulo);

  final UniqueKey key;
  final TextEditingController controller;

  String get titulo => controller.text.trim();
}

class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.label,
    required this.date,
    required this.onTap,
  });

  final String label;
  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text(
          '${date.day}/${date.month}/${date.year}',
        ),
      ),
    );
  }
}
