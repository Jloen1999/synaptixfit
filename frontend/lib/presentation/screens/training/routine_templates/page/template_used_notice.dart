import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../domain/models/training/routine.dart';
import '../../../../extensions/context_extensions.dart';
import '../../training_routes.dart';
import '../../widgets/training_section_bar.dart';

/// Tras usar una plantilla (lista o detalle): avisa de que ya es tu rutina y,
/// si trae carreras, dónde quedan con «Ver»; luego abre la rutina creada.
void announceTemplateUsed(
  BuildContext context,
  Routine routine, {
  required bool withRuns,
}) {
  final l10n = context.localizations;
  // El aviso sobrevive a esta pantalla: «Ver» usa el router, no este
  // contexto, que ya no existirá al pulsarlo.
  final router = GoRouter.of(context);
  if (withRuns) {
    // Los entrenos de carrera los creó el servidor en Correr: el aviso dice
    // dónde quedan y lleva hasta allí.
    context.showActionSnack(
      l10n.trainingTemplatesCreatedWithRuns(routine.name),
      actionLabel: l10n.commonView,
      onAction: () => router.go(TrainingPaths.section(TrainingSection.run)),
    );
  } else {
    context.showSnack(l10n.trainingTemplatesCreated(routine.name));
  }
  // La rutina vive en la pestaña de entreno: se cambia dentro de ella.
  router.go(TrainingPaths.routine(routine.id));
}
