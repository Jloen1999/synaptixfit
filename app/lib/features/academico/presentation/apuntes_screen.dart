import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/models/db_models.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/feature_scaffold.dart';
import '../application/apuntes_provider.dart';
import '../application/asignaturas_provider.dart';

class ApuntesScreen extends ConsumerStatefulWidget {
  const ApuntesScreen({
    super.key,
    this.asignaturaId,
    this.asignaturaNombre,
  });

  final String? asignaturaId;
  final String? asignaturaNombre;

  @override
  ConsumerState<ApuntesScreen> createState() => _ApuntesScreenState();
}

class _ApuntesScreenState extends ConsumerState<ApuntesScreen> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final title = widget.asignaturaNombre ?? 'Apuntes';
    final backPath = widget.asignaturaId != null ? null : '/academico';

    return FeatureScaffold(
      title: title,
      backPath: backPath,
      floatingActionButton: _tabIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => _abrirEditor(),
              icon: const Icon(Icons.add),
              label: const Text('Nuevo apunte'),
            )
          : null,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('Mis apuntes')),
                ButtonSegment(value: 1, label: Text('Explorar')),
              ],
              selected: {_tabIndex},
              onSelectionChanged: (v) => setState(() => _tabIndex = v.first),
            ),
          ),
          Expanded(
            child: _tabIndex == 0 ? _buildMisApuntes() : _buildExplorar(),
          ),
        ],
      ),
    );
  }

  Widget _buildMisApuntes() {
    final async = ref.watch(apuntesProvider);

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (apuntes) {
        final filtrados = widget.asignaturaId != null
            ? apuntes
                .where((a) => a.asignaturaId == widget.asignaturaId)
                .toList()
            : apuntes;

        if (filtrados.isEmpty) {
          return const EmptyState(
            icon: Icons.article_outlined,
            title: 'Sin apuntes',
            message: 'Crea tu primer apunte usando Markdown.',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(apuntesProvider);
            return ref.read(apuntesProvider.future);
          },
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: filtrados.length,
            itemBuilder: (context, index) {
              final a = filtrados[index];
              return _ApunteCard(
                apunte: a,
                onTap: () => _abrirEditor(apunte: a),
                onDelete: () => _confirmarEliminar(a),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildExplorar() {
    final async = ref.watch(apuntesPublicosProvider);

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (publicos) {
        if (publicos.isEmpty) {
          return const EmptyState(
            icon: Icons.public_outlined,
            title: 'Sin apuntes públicos',
            message: 'No hay apuntes públicos o de amigos disponibles.',
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(apuntesPublicosProvider);
            return ref.read(apuntesPublicosProvider.future);
          },
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: publicos.length,
            itemBuilder: (context, index) {
              final p = publicos[index];
              return _ApuntePublicoCard(dto: p);
            },
          ),
        );
      },
    );
  }

  void _abrirEditor({ApunteDb? apunte}) {
    context.push(
      '/academico/apuntes/editor',
      extra: {
        'apunteId': apunte?.id,
        'asignaturaId': widget.asignaturaId,
      },
    );
  }

  void _confirmarEliminar(ApunteDb a) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar apunte'),
        content: Text('¿Eliminar «${a.titulo}»?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await eliminarApunte(a.id);
              ref.invalidate(apuntesProvider);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

class _ApunteCard extends StatelessWidget {
  const _ApunteCard({
    required this.apunte,
    required this.onTap,
    required this.onDelete,
  });

  final ApunteDb apunte;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final preview = apunte.contenido.length > 120
        ? '${apunte.contenido.substring(0, 120)}...'
        : apunte.contenido;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: Icon(
          apunte.esNotaRapida ? Icons.push_pin : Icons.article_outlined,
        ),
        title:
            Text(apunte.titulo, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(preview, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _VisibilidadChip(visibilidad: apunte.visibilidad),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              onPressed: onDelete,
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

class _ApuntePublicoCard extends StatelessWidget {
  const _ApuntePublicoCard({required this.dto});

  final ApuntePublicoDto dto;

  @override
  Widget build(BuildContext context) {
    final apunte = dto.apunte;
    final preview = apunte.contenido.length > 120
        ? '${apunte.contenido.substring(0, 120)}...'
        : apunte.contenido;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: Icon(
          apunte.esNotaRapida ? Icons.push_pin : Icons.article_outlined,
        ),
        title:
            Text(apunte.titulo, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dto.autorNombre,
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary)),
            Text(preview, maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
        trailing: _VisibilidadChip(visibilidad: apunte.visibilidad),
        isThreeLine: true,
      ),
    );
  }
}

class _VisibilidadChip extends StatelessWidget {
  const _VisibilidadChip({required this.visibilidad});
  final String visibilidad;

  @override
  Widget build(BuildContext context) {
    final color = switch (visibilidad) {
      'public' => Colors.green,
      'solo_amigos' => Colors.orange,
      _ => Colors.grey,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        visibilidad == 'solo_amigos' ? 'amigos' : visibilidad,
        style: TextStyle(fontSize: 10, color: color),
      ),
    );
  }
}

class ApuntesEditorScreen extends ConsumerStatefulWidget {
  const ApuntesEditorScreen({super.key});

  @override
  ConsumerState<ApuntesEditorScreen> createState() =>
      _ApuntesEditorScreenState();
}

class _ApuntesEditorScreenState extends ConsumerState<ApuntesEditorScreen> {
  String? _apunteId;
  final _tituloCtrl = TextEditingController();
  final _contenidoCtrl = TextEditingController();
  String? _asignaturaId;
  String _visibilidad = 'private';
  bool _mostrandoPreview = false;
  bool _esNotaRapida = false;

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _contenidoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
    _apunteId ??= extra?['apunteId'] as String?;
    _asignaturaId ??= extra?['asignaturaId'] as String?;
    final editando = _apunteId != null;

    if (editando) {
      final apunteAsync = ref.watch(apunteDetalleProvider(_apunteId!));
      return apunteAsync.when(
        loading: () => const FeatureScaffold(
          title: 'Cargando...',
          backPath: '/academico/apuntes',
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => FeatureScaffold(
          title: 'Error',
          backPath: '/academico/apuntes',
          child: Center(child: Text('Error al cargar: $e')),
        ),
        data: (apunte) {
          if (apunte == null) {
            return const FeatureScaffold(
              title: 'Error',
              backPath: '/academico/apuntes',
              child: Center(child: Text('Apunte no encontrado')),
            );
          }
          _inicializarDesdeApunte(apunte);
          return _buildEditorScaffold(editando);
        },
      );
    }

    return _buildEditorScaffold(editando);
  }

  void _inicializarDesdeApunte(ApunteDb apunte) {
    if (_tituloCtrl.text.isEmpty && _contenidoCtrl.text.isEmpty) {
      _tituloCtrl.text = apunte.titulo;
      _contenidoCtrl.text = apunte.contenido;
      _visibilidad = apunte.visibilidad;
      _esNotaRapida = apunte.esNotaRapida;
      _asignaturaId ??= apunte.asignaturaId;
    }
  }

  Widget _buildEditorScaffold(bool editando) {
    return FeatureScaffold(
      title: editando ? 'Editar apunte' : 'Nuevo apunte',
      backPath: '/academico/apuntes',
      actions: [
        IconButton(
          icon: Icon(_mostrandoPreview
              ? Icons.edit_outlined
              : Icons.visibility_outlined),
          tooltip: _mostrandoPreview ? 'Editar' : 'Vista previa',
          onPressed: () =>
              setState(() => _mostrandoPreview = !_mostrandoPreview),
        ),
        IconButton(
          icon: const Icon(Icons.save_outlined),
          tooltip: 'Guardar',
          onPressed: _guardar,
        ),
      ],
      child: _mostrandoPreview ? _buildPreview() : _buildEditor(),
    );
  }

  Widget _buildEditor() {
    final asignaturasAsync = ref.watch(asignaturasActivasProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _tituloCtrl,
          decoration: const InputDecoration(
            labelText: 'Título',
            hintText: 'ej: Resumen Tema 3 - Álgebra Lineal',
          ),
          textCapitalization: TextCapitalization.sentences,
        ),
        const SizedBox(height: 12),
        asignaturasAsync.when(
          data: (asigs) => DropdownButtonFormField<String>(
            initialValue: _asignaturaId,
            isExpanded: true,
            decoration:
                const InputDecoration(labelText: 'Asignatura (opcional)'),
            items: [
              const DropdownMenuItem(
                  value: null, child: Text('Sin asignatura')),
              ...asigs.map((a) => DropdownMenuItem(
                  value: a.id,
                  child: Text(a.nombre, overflow: TextOverflow.ellipsis))),
            ],
            onChanged: (v) => setState(() => _asignaturaId = v),
          ),
          loading: () =>
              const SizedBox(height: 48, child: LinearProgressIndicator()),
          error: (_, __) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _visibilidad,
                decoration: const InputDecoration(labelText: 'Visibilidad'),
                items: const [
                  DropdownMenuItem(value: 'private', child: Text('Privado')),
                  DropdownMenuItem(value: 'public', child: Text('Público')),
                  DropdownMenuItem(
                      value: 'solo_amigos', child: Text('Solo amigos')),
                ],
                onChanged: (v) => setState(() => _visibilidad = v!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SwitchListTile.adaptive(
          title: const Text('Nota rápida'),
          subtitle: const Text('Marcar como nota informal'),
          value: _esNotaRapida,
          onChanged: (v) => setState(() => _esNotaRapida = v),
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: 12),
        Text('Contenido (Markdown)',
            style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 8),
        TextField(
          controller: _contenidoCtrl,
          maxLines: 20,
          decoration: const InputDecoration(
            hintText:
                '# Título\n\nTexto del apunte.\n\n- Item 1\n- Item 2\n\n**Negrita** *Itálica*',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          textCapitalization: TextCapitalization.sentences,
        ),
      ],
    );
  }

  Widget _buildPreview() {
    if (_contenidoCtrl.text.trim().isEmpty) {
      return const Center(child: Text('Sin contenido para previsualizar.'));
    }
    return Markdown(
      data: _contenidoCtrl.text,
      selectable: true,
    );
  }

  Future<void> _guardar() async {
    final titulo = _tituloCtrl.text.trim();
    if (titulo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('El título es obligatorio.'),
            backgroundColor: Colors.red),
      );
      return;
    }

    if (_apunteId != null) {
      await actualizarApunte(
        id: _apunteId!,
        titulo: titulo,
        contenido: _contenidoCtrl.text,
        asignaturaId: _asignaturaId,
        visibilidad: _visibilidad,
        esNotaRapida: _esNotaRapida,
      );
    } else {
      await crearApunte(
        titulo: titulo,
        contenido: _contenidoCtrl.text,
        asignaturaId: _asignaturaId,
        visibilidad: _visibilidad,
        esNotaRapida: _esNotaRapida,
      );
    }

    if (mounted) {
      ref.invalidate(apuntesProvider);
      context.pop();
    }
  }
}
