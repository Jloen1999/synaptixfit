import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/widgets/feature_scaffold.dart';
import '../../../shared/widgets/sv_primary_button.dart';
import '../application/retos_provider.dart';

class CrearRetoSimpleScreen extends ConsumerStatefulWidget {
  const CrearRetoSimpleScreen({super.key});

  @override
  ConsumerState<CrearRetoSimpleScreen> createState() =>
      _CrearRetoSimpleScreenState();
}

class _CrearRetoSimpleScreenState extends ConsumerState<CrearRetoSimpleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _metaController = TextEditingController();

  String _tipo = 'fitness';
  String _visibilidad = 'private';
  DateTime _fechaInicio = DateTime.now();
  DateTime _fechaFin = DateTime.now().add(const Duration(days: 7));
  bool _guardando = false;

  @override
  void dispose() {
    _tituloController.dispose();
    _metaController.dispose();
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

  Future<void> _crearRetoSimple() async {
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

      ref.invalidate(retosProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reto simple creado correctamente.')),
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
    return FeatureScaffold(
      title: 'Crear Reto Simple',
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
                if (texto.length < 5) {
                  return 'El título debe tener al menos 5 caracteres.';
                }
                if (texto.length > 80) {
                  return 'El título no puede superar 80 caracteres.';
                }
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
                labelText: 'Meta',
                hintText: 'Ejemplo: Correr 20 km en 4 semanas',
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
            const SizedBox(height: 20),
            SVPrimaryButton(
              label: _guardando ? 'Creando reto...' : 'Publicar reto',
              icon: Icons.flag_circle_outlined,
              onPressed: _guardando ? null : _crearRetoSimple,
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
