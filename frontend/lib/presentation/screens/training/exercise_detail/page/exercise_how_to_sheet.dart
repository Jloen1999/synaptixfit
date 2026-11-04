import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../widgets/exercise_instructions.dart';
import '../../widgets/exercise_media.dart';
import '../../../../../domain/models/training/exercise.dart';
import '../../exercise_guide/page/exercise_guide_section.dart';
import '../bloc/exercise_detail_bloc.dart';

/// Abre la hoja «Cómo se hace»: demostración e instrucciones de un ejercicio
/// sin salir de la pantalla actual (p. ej. la sesión en vivo). La ficha se
/// carga con [ExerciseDetailBloc]; mientras, se ve ya la demostración que se
/// conoce del ejercicio planificado.
Future<void> showExerciseHowToSheet(
  BuildContext context, {
  required String exerciseId,
  required String name,
  String? gifUrl,
  String? previewUrl,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  useSafeArea: true,
  builder: (_) => BlocProvider(
    create: (_) =>
        getIt<ExerciseDetailBloc>()
          ..add(ExerciseDetailEvent.started(exerciseId)),
    child: _HowToSheet(
      exerciseId: exerciseId,
      name: name,
      gifUrl: gifUrl,
      previewUrl: previewUrl,
    ),
  ),
);

class _HowToSheet extends StatelessWidget {
  const _HowToSheet({
    required this.exerciseId,
    required this.name,
    required this.gifUrl,
    required this.previewUrl,
  });

  final String exerciseId;
  final String name;
  final String? gifUrl;
  final String? previewUrl;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 1,
      builder: (context, controller) =>
          BlocBuilder<ExerciseDetailBloc, ExerciseDetailState>(
            builder: (context, state) {
              final loaded = switch (state) {
                ExerciseDetailLoaded(:final exercise) => exercise,
                _ => null,
              };
              return ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(
                  TokensSpacing.l,
                  0,
                  TokensSpacing.l,
                  TokensSpacing.l,
                ),
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Semantics(
                          header: true,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.trainingHowTo,
                                style: context.textStyles.labelLarge?.copyWith(
                                  color: context.colors.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                loaded?.name ?? name,
                                style: context.textStyles.titleLarge,
                              ),
                            ],
                          ),
                        ),
                      ),
                      // A pantalla completa no se ve el fondo que la cierra:
                      // cerrar con un botón, sin depender del gesto.
                      IconButton(
                        tooltip: MaterialLocalizations.of(
                          context,
                        ).closeButtonTooltip,
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: TokensSpacing.m),
                  // Primero la demostración ya conocida: así el vídeo no se
                  // reinicia cuando llega la ficha completa.
                  ExerciseMedia(
                    gifUrl: gifUrl ?? loaded?.gifUrl,
                    previewUrl: previewUrl ?? loaded?.previewUrl,
                    semanticLabel: l10n.trainingExerciseDemo(
                      loaded?.name ?? name,
                    ),
                  ),
                  const SizedBox(height: TokensSpacing.l),
                  switch (state) {
                    ExerciseDetailLoading() => const AppLoadingView(),
                    ExerciseDetailFailure(:final error) => AppErrorView(
                      error: error,
                      onRetry: () => context.read<ExerciseDetailBloc>().add(
                        ExerciseDetailEvent.started(exerciseId),
                      ),
                    ),
                    ExerciseDetailLoaded(:final exercise) => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (exercise.instructions.isEmpty)
                          Text(
                            l10n.trainingHowToEmpty,
                            style: context.textStyles.bodyMedium?.copyWith(
                              color: context.colors.onSurfaceVariant,
                            ),
                          )
                        else ...[
                          AppSectionHeader(title: l10n.trainingInstructions),
                          ExerciseInstructions(steps: exercise.instructions),
                        ],
                        _WorksWith(exercise: exercise),
                        ExerciseGuideSection(exerciseId: exercise.id),
                      ],
                    ),
                  },
                ],
              );
            },
          ),
    );
  }
}

/// «Qué trabaja · Material» en una línea cada uno: lo justo para saber si es
/// el ejercicio que buscas sin salir de la sesión.
class _WorksWith extends StatelessWidget {
  const _WorksWith({required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final muscles = [for (final m in exercise.targetMuscles) m.name];
    final equipment = [for (final e in exercise.equipment) e.name];
    if (muscles.isEmpty && equipment.isEmpty) return const SizedBox.shrink();
    Widget line(IconData icon, String label, List<String> items) => Padding(
      padding: const EdgeInsets.only(top: TokensSpacing.s),
      child: MergeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: Icon(
                icon,
                size: TokensSize.iconS,
                color: context.colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: TokensSpacing.s),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '$label: ',
                      style: context.textStyles.labelLarge,
                    ),
                    TextSpan(text: items.join(', ')),
                  ],
                ),
                style: context.textStyles.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(top: TokensSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (muscles.isNotEmpty)
            line(
              Icons.accessibility_new_rounded,
              l10n.trainingWorksLabel,
              muscles,
            ),
          if (equipment.isNotEmpty)
            line(
              Icons.fitness_center_rounded,
              l10n.trainingEquipmentLabel,
              equipment,
            ),
        ],
      ),
    );
  }
}
