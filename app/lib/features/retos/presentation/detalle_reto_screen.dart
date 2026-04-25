import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/challenge_progress_bar.dart';
import '../../../shared/widgets/feature_scaffold.dart';
import '../../../shared/widgets/feed_card.dart';
import '../../../shared/widgets/milestone_card.dart';
import '../application/retos_provider.dart';

class DetalleRetoScreen extends ConsumerWidget {
  const DetalleRetoScreen({required this.id, super.key});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detalleAsync = ref.watch(retoDetalleProvider(id));

    return detalleAsync.when(
      loading: () => const FeatureScaffold(
        title: 'Detalle de Reto',
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => FeatureScaffold(
        title: 'Detalle de Reto',
        child: Center(child: Text('Error: $e')),
      ),
      data: (detalle) {
        if (detalle == null) {
          return const FeatureScaffold(
            title: 'Detalle de Reto',
            child: Center(child: Text('Reto no encontrado')),
          );
        }

        return FeatureScaffold(
          title: detalle.reto.titulo,
          backPath: '/retos',
          floatingActionButton: FloatingActionButton(
            onPressed: () {},
            child: const Icon(Icons.share_outlined),
          ),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ChallengeProgressBar(
                  progress: detalle.progresoGeneral, label: 'Progreso general'),
              const SizedBox(height: 16),
              ...detalle.hitos.map(
                (hito) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: MilestoneCard(
                    title: hito.titulo,
                    weight: hito.porcentajePeso,
                    progress:
                        (hito.progresoActual / 100).clamp(0.0, 1.0).toDouble(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FeedCard(
                userName: 'Comunidad',
                achievement: detalle.actividadRelacionada?.descripcion ??
                    'Hoy completaste un avance importante en tu reto.',
                likes: detalle.likes,
                comments: detalle.comentarios,
              ),
            ],
          ),
        );
      },
    );
  }
}
