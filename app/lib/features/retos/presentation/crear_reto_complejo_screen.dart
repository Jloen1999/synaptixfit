import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/widgets/feature_scaffold.dart';
import '../../../shared/widgets/milestone_card.dart';
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

  final List<_HitoDraft> _hitos = [
    _HitoDraft(titulo: 'Primer hito', peso: 50),
    _HitoDraft(titulo: 'Segundo hito', peso: 50),
  ];

  @override
  void dispose() {
    _tituloController.dispose();
    _metaController.dispose();
    for (final hito in _hitos) {
      hito.dispose();
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
      helpText:
          inicio ? 'Selecciona fecha de inicio' : 'Selecciona fecha de fin',
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

  void _agregarHito() {
    if (_hitos.length >= 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Máximo 8 hitos por reto complejo.')),
      );
      return;
    }

    setState(() {
      _hitos.add(_HitoDraft(titulo: 'Nuevo hito', peso: 10));
    });
  }

  void _eliminarHito(int index) {
    if (_hitos.length <= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Un reto complejo debe tener al menos 2 hitos.')),
      );
      return;
    }

    setState(() {
      final eliminado = _hitos.removeAt(index);
      eliminado.dispose();
    });
  }

  double get _sumaPesos {
    return _hitos.fold<double>(
      0,
      (total, hito) => total + hito.peso,
    );
  }

  Future<void> _crearRetoComplejo() async {
    if (_guardando) return;
    if (!_formKey.currentState!.validate()) return;

    if (!_fechaFin.isAfter(_fechaInicio)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('La fecha de fin debe ser posterior a la fecha de inicio.'),
        ),
      );
      return;
    }

    if (_hitos.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega al menos 2 hitos.')),
      );
      return;
    }

    for (var i = 0; i < _hitos.length; i++) {
      final hito = _hitos[i];
      if (hito.titulo.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('El hito ${i + 1} necesita un título.')),
        );
        return;
      }
      if (hito.peso <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('El hito ${i + 1} debe tener peso mayor a 0.')),
        );
        return;
      }
    }

    final suma = _sumaPesos;
    if ((suma - 100).abs() > 0.01) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'La suma de pesos debe ser 100%. Actualmente: ${suma.toStringAsFixed(1)}%'),
        ),
      );
      return;
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

      final hitosInsert = <Map<String, dynamic>>[];
      for (var i = 0; i < _hitos.length; i++) {
        final hito = _hitos[i];
        hitosInsert.add({
          'reto_id': retoId,
          'titulo': hito.titulo,
          'porcentaje_peso': hito.peso,
          'indice_orden': i + 1,
          'progreso_actual': 0,
          'esta_completado': false,
        });
      }

      await client.from('hitos_de_reto').insert(hitosInsert);

      ref.invalidate(retosProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reto complejo creado correctamente.')),
      );
      context.go('/retos/$retoId');
    } on PostgrestException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al crear reto: ${error.message}')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo crear el reto: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _guardando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sumaPesos = _sumaPesos;
    final sumaValida = (sumaPesos - 100).abs() <= 0.01;

    return FeatureScaffold(
      title: 'Crear Reto Complejo',
      backPath: '/retos',
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _tituloController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Título del reto'),
              validator: (value) {
                final texto = value?.trim() ?? '';
                if (texto.isEmpty) return 'El título es obligatorio.';
                if (texto.length < 5)
                  return 'El título debe tener al menos 5 caracteres.';
                if (texto.length > 80)
                  return 'El título no puede superar 80 caracteres.';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _metaController,
              textInputAction: TextInputAction.next,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Meta del reto',
                hintText:
                    'Ejemplo: Mejorar rendimiento académico y físico en 30 días',
              ),
              validator: (value) {
                final texto = value?.trim() ?? '';
                if (texto.isEmpty) return 'La meta es obligatoria.';
                if (texto.length < 3) return 'La meta es demasiado corta.';
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _tipo,
              items: const [
                DropdownMenuItem(value: 'fitness', child: Text('Fitness')),
                DropdownMenuItem(value: 'academic', child: Text('Académico')),
              ],
              onChanged: _guardando
                  ? null
                  : (value) {
                      if (value == null) return;
                      setState(() => _tipo = value);
                    },
              decoration: const InputDecoration(labelText: 'Tipo de reto'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _visibilidad,
              items: const [
                DropdownMenuItem(value: 'private', child: Text('Privado')),
                DropdownMenuItem(value: 'friends', child: Text('Amigos')),
                DropdownMenuItem(value: 'public', child: Text('Público')),
              ],
              onChanged: _guardando
                  ? null
                  : (value) {
                      if (value == null) return;
                      setState(() => _visibilidad = value);
                    },
              decoration: const InputDecoration(labelText: 'Visibilidad'),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Fecha de inicio'),
              subtitle: Text(_formatearFecha(_fechaInicio)),
              trailing: const Icon(Icons.calendar_month_outlined),
              onTap: _guardando ? null : () => _seleccionarFecha(inicio: true),
            ),
            const Divider(height: 1),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Fecha de fin'),
              subtitle: Text(_formatearFecha(_fechaFin)),
              trailing: const Icon(Icons.event_available_outlined),
              onTap: _guardando ? null : () => _seleccionarFecha(inicio: false),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text('Hitos', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                TextButton.icon(
                  onPressed: _guardando ? null : _agregarHito,
                  icon: const Icon(Icons.add),
                  label: const Text('Añadir hito'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < _hitos.length; i++) ...[
              _HitoFormCard(
                index: i,
                draft: _hitos[i],
                bloqueado: _guardando,
                onEliminar: () => _eliminarHito(i),
                onChanged: () => setState(() {}),
              ),
              const SizedBox(height: 8),
              MilestoneCard(
                title: _hitos[i].titulo.isEmpty
                    ? 'Hito ${i + 1}'
                    : _hitos[i].titulo,
                weight: _hitos[i].peso,
                progress:
                    (_hitos[i].progresoActual / 100).clamp(0.0, 1.0).toDouble(),
              ),
              const SizedBox(height: 12),
            ],
            Text(
              'Suma de pesos: ${sumaPesos.toStringAsFixed(1)}%',
              style: TextStyle(
                color: sumaValida
                    ? Colors.green
                    : Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            SVPrimaryButton(
              label: _guardando ? 'Creando reto...' : 'Publicar reto',
              icon: Icons.flag_circle_outlined,
              onPressed: _guardando ? null : _crearRetoComplejo,
            ),
          ],
        ),
      ),
    );
  }

  String _formatearFecha(DateTime fecha) {
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    return '$dia/$mes/${fecha.year}';
  }
}

class _HitoDraft {
  _HitoDraft({required String titulo, required double peso})
      : tituloController = TextEditingController(text: titulo),
        pesoController = TextEditingController(text: peso.toStringAsFixed(0));

  final TextEditingController tituloController;
  final TextEditingController pesoController;

  String get titulo => tituloController.text.trim();

  double get peso {
    return double.tryParse(pesoController.text.trim().replaceAll(',', '.')) ??
        0;
  }

  double get progresoActual => 0;

  void dispose() {
    tituloController.dispose();
    pesoController.dispose();
  }
}

class _HitoFormCard extends StatelessWidget {
  const _HitoFormCard({
    required this.index,
    required this.draft,
    required this.bloqueado,
    required this.onEliminar,
    required this.onChanged,
  });

  final int index;
  final _HitoDraft draft;
  final bool bloqueado;
  final VoidCallback onEliminar;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  'Hito ${index + 1}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: bloqueado ? null : onEliminar,
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Eliminar hito',
                ),
              ],
            ),
            TextField(
              controller: draft.tituloController,
              enabled: !bloqueado,
              onChanged: (_) => onChanged(),
              decoration: const InputDecoration(
                labelText: 'Título del hito',
                hintText: 'Ejemplo: Completar semana 1',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: draft.pesoController,
              enabled: !bloqueado,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => onChanged(),
              decoration: const InputDecoration(
                labelText: 'Peso (%)',
                hintText: 'Ejemplo: 25',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
