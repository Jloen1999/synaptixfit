import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/design_system/sv_colors.dart';
import '../../../core/design_system/sv_shapes.dart';
import '../../perfil/application/perfil_provider.dart';
import '../application/artefacto_efimero_provider.dart';
import '../application/materiales_estudio_provider.dart';

/// Vista previa de las tarjetas de estudio generadas por IA.
///
/// Muestra cada pregunta como una flashcard con número, enunciado,
/// respuesta correcta y explicación opcional. Permite guardar todo
/// el conjunto en [materiales_estudio] para repaso SM-2 posterior.
class TarjetasEstudioScreen extends ConsumerStatefulWidget {
  const TarjetasEstudioScreen({super.key});

  @override
  ConsumerState<TarjetasEstudioScreen> createState() =>
      _TarjetasEstudioScreenState();
}

class _TarjetasEstudioScreenState extends ConsumerState<TarjetasEstudioScreen> {
  bool _guardando = false;
  final Map<int, TextEditingController> _editPregunta = {};
  final Map<int, TextEditingController> _editRespuesta = {};
  int? _editandoIndice;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(artefactoEfimeroProvider);

    return Scaffold(
      backgroundColor: SVColors.surfaceContainerLowest,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: SVColors.surfaceContainerLowest,
        surfaceTintColor: SVColors.surfaceContainerLowest,
        title: Text(
          state.tituloEfectivo,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: SVColors.onSurface,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _buildBody(state),
      bottomNavigationBar: _buildBottomBar(state),
    );
  }

  /// Construye el cuerpo según el [EstadoGeneracion].
  Widget _buildBody(ArtefactoEfimeroState state) {
    if (state.estado == EstadoGeneracion.cargando) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: SVColors.primary),
            SizedBox(height: 16),
            Text(
              'Generando preguntas...',
              style: TextStyle(color: SVColors.onSurfaceMuted),
            ),
          ],
        ),
      );
    }

    if (state.estado == EstadoGeneracion.error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: SVColors.error),
              const SizedBox(height: 12),
              Text(
                state.error ?? 'Error desconocido',
                textAlign: TextAlign.center,
                style: const TextStyle(color: SVColors.error),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  ref.read(artefactoEfimeroProvider.notifier).regenerar();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    // ── Estado completado: mostrar las tarjetas ──
    final preguntas = state.preguntas;
    if (preguntas.isEmpty) {
      return const Center(
        child: Text(
          'No hay preguntas generadas.',
          style: TextStyle(color: SVColors.onSurfaceMuted),
        ),
      );
    }

    return SafeArea(
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: preguntas.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          return _buildFlashcard(preguntas[index], index, preguntas.length);
        },
      ),
    );
  }

  /// Tarjeta individual con número, enunciado y respuesta.
  Widget _buildFlashcard(
    PreguntaGenerada pregunta,
    int index,
    int total,
  ) {
    final numero = '${index + 1}/$total';
    final editando = _editandoIndice == index;

    return Material(
      color: SVColors.surfaceContainerLow,
      borderRadius: SVShapes.standard12,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: SVColors.primary.withOpacity(0.1),
                    borderRadius: SVShapes.pill,
                  ),
                  child: Text(
                    numero,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: SVColors.primary,
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _tipoChip(pregunta.tipo),
                    const SizedBox(width: 4),
                    IconButton(
                      onPressed: () => _toggleEdicion(index, pregunta),
                      icon: Icon(
                        editando ? Icons.check : Icons.edit_outlined,
                        size: 18,
                      ),
                      color: SVColors.onSurfaceMuted,
                      visualDensity: VisualDensity.compact,
                      tooltip: editando ? 'Guardar cambios' : 'Editar',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            editando
                ? TextField(
                    controller: _editPregunta.putIfAbsent(index,
                        () => TextEditingController(text: pregunta.enunciado)),
                    maxLines: 3,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: SVColors.onSurface,
                      fontSize: 15,
                    ),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                  )
                : Text(
                    pregunta.enunciado,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: SVColors.onSurface,
                        ),
                  ),
            const SizedBox(height: 10),
            Container(height: 1, color: SVColors.outlineVariant),
            const SizedBox(height: 10),
            editando
                ? TextField(
                    controller: _editRespuesta.putIfAbsent(
                        index,
                        () => TextEditingController(
                            text: pregunta.respuestaCorrecta)),
                    maxLines: 2,
                    style: const TextStyle(
                      color: SVColors.secondary,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                  )
                : Text(
                    pregunta.respuestaCorrecta,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: SVColors.secondary,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
            if (pregunta.explicacion != null &&
                pregunta.explicacion!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                pregunta.explicacion!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: SVColors.onSurfaceMuted,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _toggleEdicion(int index, PreguntaGenerada p) {
    if (_editandoIndice == index) {
      _aplicarEdicion(index, p);
      setState(() => _editandoIndice = null);
    } else {
      _editPregunta[index] = TextEditingController(text: p.enunciado);
      _editRespuesta[index] = TextEditingController(text: p.respuestaCorrecta);
      setState(() => _editandoIndice = index);
    }
  }

  void _aplicarEdicion(int index, PreguntaGenerada p) {
    final nuevoEnunciado = _editPregunta[index]?.text.trim();
    final nuevaRespuesta = _editRespuesta[index]?.text.trim();
    if (nuevoEnunciado != null && nuevoEnunciado.isNotEmpty) {
      p.enunciado = nuevoEnunciado;
    }
    if (nuevaRespuesta != null && nuevaRespuesta.isNotEmpty) {
      p.respuestaCorrecta = nuevaRespuesta;
    }
    _editPregunta[index]?.dispose();
    _editRespuesta[index]?.dispose();
    _editPregunta.remove(index);
    _editRespuesta.remove(index);
  }

  @override
  void dispose() {
    for (final c in _editPregunta.values) {
      c.dispose();
    }
    for (final c in _editRespuesta.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// Chip indicador de tipo de pregunta.
  Widget _tipoChip(String tipo) {
    final color = tipo == 'tarjeta' ? SVColors.primary : SVColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: SVShapes.pill,
      ),
      child: Text(
        tipo == 'tarjeta' ? 'Tarjeta' : tipo,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  /// Barra inferior con acciones: regenerar, descartar, guardar.
  Widget _buildBottomBar(ArtefactoEfimeroState state) {
    final puedeGuardar =
        state.estado == EstadoGeneracion.completado && !_guardando;

    return Container(
      decoration: const BoxDecoration(
        color: SVColors.surfaceContainerLowest,
        border: Border(
          top: BorderSide(color: SVColors.outlineVariant, width: 0.5),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        8,
        8,
        8,
        MediaQuery.of(context).padding.bottom + 8,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // ── Regenerar ──
            IconButton(
              onPressed: _guardando
                  ? null
                  : () =>
                      ref.read(artefactoEfimeroProvider.notifier).regenerar(),
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Regenerar',
              color: SVColors.onSurfaceVariant,
            ),
            // ── Descartar ──
            IconButton(
              onPressed: _guardando ? null : () => Navigator.of(context).pop(),
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'Descartar',
              color: SVColors.error,
            ),
            const Spacer(),
            // ── Guardar para repasar ──
            FilledButton.icon(
              onPressed: puedeGuardar ? _guardarParaRepasar : null,
              icon: _guardando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: SVColors.onPrimary,
                      ),
                    )
                  : const Icon(Icons.save_alt_rounded, size: 20),
              label: Text(_guardando ? 'Guardando...' : 'Guardar para repasar'),
              style: FilledButton.styleFrom(
                backgroundColor: SVColors.primary,
                foregroundColor: SVColors.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: SVShapes.standard12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _genUuid() {
    final r = math.Random();
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replaceAllMapped(
      RegExp(r'[xy]'),
      (m) {
        final c = m[0] == 'x' ? r.nextInt(16) : (r.nextInt(4) + 8);
        return c.toRadixString(16);
      },
    );
  }

  ///
  /// Flujo:
  /// 1. Inserta un registro en [materiales_estudio] con tipo 'ia_flashcards'.
  /// 2. Crea un [bancos_preguntas] vinculado.
  /// 3. Inserta cada pregunta en [preguntas].
  /// 4. Invalida el provider de materiales para refrescar la UI.
  Future<void> _guardarParaRepasar() async {
    final state = ref.read(artefactoEfimeroProvider);
    final preguntas = state.preguntas;
    if (preguntas.isEmpty) return;

    setState(() => _guardando = true);

    try {
      final client = Supabase.instance.client;
      final userId = ref.read(currentUserIdProvider);
      final titulo = state.tituloEfectivo;
      final asignaturaId = state.asignaturaId;

      final matInsert = <String, dynamic>{
        'tipo_origen': 'ia_flashcards',
        'origen_id': _genUuid(),
        'titulo': titulo,
        if (userId != null) 'usuario_id': userId,
        if (asignaturaId != null) 'asignatura_id': asignaturaId,
      };

      final matRow = await client
          .from('materiales_estudio')
          .insert(matInsert)
          .select()
          .single();
      final materialId = matRow['id'] as String;

      // 2. Crear banco de preguntas vinculado al material.
      final bancoRow = await client
          .from('bancos_preguntas')
          .insert({
            'material_id': materialId,
            if (userId != null) 'usuario_id': userId,
          })
          .select()
          .single();
      final bancoId = bancoRow['id'] as String;

      // 3. Insertar cada pregunta.
      final preguntasRows = <Map<String, dynamic>>[];
      for (var i = 0; i < preguntas.length; i++) {
        final p = preguntas[i];
        preguntasRows.add({
          'banco_id': bancoId,
          'tipo': p.tipo,
          'enunciado': p.enunciado,
          'opciones': p.opciones,
          'respuesta_correcta': p.respuestaCorrecta,
          'explicacion': p.explicacion,
          'orden': i,
        });
      }
      await client.from('preguntas').insert(preguntasRows);

      // 4. Invalidar el provider de materiales si hay asignatura.
      if (asignaturaId != null && mounted) {
        ref.invalidate(materialesAsignaturaProvider(asignaturaId));
        ref.invalidate(materialesAsignaturaProvider(asignaturaId));
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Flashcards guardados para repasar'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: SVColors.error,
        ),
      );
    }
  }
}
