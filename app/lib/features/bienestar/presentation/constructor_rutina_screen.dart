import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/feature_scaffold.dart';
import '../../../shared/widgets/sv_primary_button.dart';
import '../application/rutina_provider.dart';

Future<void> _guardarRutina(WidgetRef ref, BuildContext context) async {
  final notifier = ref.read(rutinaProvider.notifier);
  final scaffold = ScaffoldMessenger.of(context);

  final result = await notifier.guardarRutina();
  if (result != null && context.mounted) {
    scaffold.showSnackBar(
      const SnackBar(content: Text('Rutina guardada correctamente')),
    );
  } else if (context.mounted) {
    scaffold.showSnackBar(
      const SnackBar(
        content: Text('Error al guardar la rutina'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

class ConstructorRutinaScreen extends ConsumerWidget {
  const ConstructorRutinaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(rutinaProvider);
    final notifier = ref.read(rutinaProvider.notifier);

    return FeatureScaffold(
      title: 'Constructor de Rutina',
      backPath: '/dashboard',
      child: Column(
        children: [
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.items.length,
              onReorder: notifier.reorder,
              itemBuilder: (context, index) {
                final item = state.items[index];
                return Card(
                  key: ValueKey(item.id),
                  child: ListTile(
                    title: Text(item.nombre),
                    subtitle: Text(
                        '${item.series} x ${item.repeticiones} · Descanso ${item.segundosDescanso}s'),
                    leading: const Icon(Icons.drag_handle),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => notifier.remove(item.id),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final showInline = constraints.maxWidth >= 600;
                if (showInline) {
                  return Row(
                    children: [
                      Expanded(
                        child: SVPrimaryButton(
                          label: 'Guardar rutina',
                          onPressed: state.items.isEmpty
                              ? null
                              : () => _guardarRutina(ref, context),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () =>
                              context.push('/bienestar/ejercicios'),
                          child: const Text('Agregar más ejercicios'),
                        ),
                      ),
                    ],
                  );
                }

                return Column(
                  children: [
                    SVPrimaryButton(
                      label: 'Guardar rutina',
                      onPressed: state.items.isEmpty
                          ? null
                          : () => _guardarRutina(ref, context),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () => context.push('/bienestar/ejercicios'),
                      child: const Text('Agregar más ejercicios'),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
