import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/challenge_progress_bar.dart';
import '../../../shared/widgets/feature_scaffold.dart';
import '../application/retos_provider.dart';

class RetosScreen extends ConsumerWidget {
  const RetosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final retosAsync = ref.watch(retosProvider);

    return FeatureScaffold(
      title: 'Retos',
      child: retosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (retos) => LayoutBuilder(
          builder: (context, constraints) {
            final stackedButtons = constraints.maxWidth < 680;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (stackedButtons)
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => context.go('/retos/simple'),
                          child: const Text('Nuevo reto simple'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => context.go('/retos/complejo'),
                          child: const Text('Nuevo reto complejo'),
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => context.go('/retos/simple'),
                          child: const Text('Nuevo reto simple'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => context.go('/retos/complejo'),
                          child: const Text('Nuevo reto complejo'),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                ...retos.map(
                  (item) => Card(
                    child: ListTile(
                      title: Text(item.reto.titulo),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: ChallengeProgressBar(progress: item.progreso),
                      ),
                      onTap: () => context.go('/retos/${item.reto.id}'),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
