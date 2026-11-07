import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../training_routes.dart';

/// Apartados de la pestaña Entreno. Se elige con `?section=` en `/training`,
/// así cada apartado tiene su enlace y la barra inferior se conserva. Para
/// añadir uno (p. ej. CrossFit) basta un valor aquí, su texto y su pantalla
/// en `trainingBranchRoutes`.
enum TrainingSection {
  gym('gym', Icons.fitness_center_rounded),
  run('run', Icons.directions_run_rounded);

  const TrainingSection(this.query, this.icon);

  final String query;
  final IconData icon;

  static TrainingSection fromQuery(String? value) =>
      values.where((s) => s.query == value).firstOrNull ?? gym;

  String label(BuildContext context) => switch (this) {
    TrainingSection.gym => context.localizations.trainingSectionGym,
    TrainingSection.run => context.localizations.trainingSectionRun,
  };
}

/// Selector «Gimnasio | Correr» bajo la barra de Entreno. Cambia de apartado
/// con `go` (misma pestaña, otra consulta): no apila pantallas.
class TrainingSectionBar extends StatelessWidget
    implements PreferredSizeWidget {
  const TrainingSectionBar({super.key, required this.current});

  final TrainingSection current;

  @override
  Size get preferredSize =>
      const Size.fromHeight(TokensLayout.minTouchTarget + TokensSpacing.m);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TokensSpacing.m,
        0,
        TokensSpacing.m,
        TokensSpacing.s,
      ),
      child: SizedBox(
        width: double.infinity,
        child: SegmentedButton<TrainingSection>(
          showSelectedIcon: false,
          segments: [
            for (final s in TrainingSection.values)
              ButtonSegment(
                value: s,
                icon: Icon(s.icon),
                label: Text(s.label(context)),
              ),
          ],
          selected: {current},
          onSelectionChanged: (selected) {
            final next = selected.first;
            if (next != current) context.go(TrainingPaths.section(next));
          },
        ),
      ),
    );
  }
}
