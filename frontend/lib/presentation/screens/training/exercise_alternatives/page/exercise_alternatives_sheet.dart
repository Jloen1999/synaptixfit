import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/models/training/exercise.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../training_routes.dart';
import '../../widgets/exercise_thumbnail.dart';
import '../../widgets/training_labels.dart';
import '../bloc/exercise_alternatives_bloc.dart';

/// Abre «Cambiar ejercicio» y devuelve el elegido (o `null` si se cierra).
Future<Exercise?> showExerciseAlternativesSheet(
  BuildContext context, {
  required String exerciseId,
  required String exerciseName,
}) => showModalBottomSheet<Exercise>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (_) => BlocProvider(
    create: (_) =>
        getIt<ExerciseAlternativesBloc>()
          ..add(ExerciseAlternativesEvent.started(exerciseId)),
    child: _AlternativesView(
      exerciseId: exerciseId,
      exerciseName: exerciseName,
    ),
  ),
);

class _AlternativesView extends StatelessWidget {
  const _AlternativesView({
    required this.exerciseId,
    required this.exerciseName,
  });

  final String exerciseId;
  final String exerciseName;

  /// Sin alternativas, se elige del catálogo completo: el usuario puede
  /// cambiar el ejercicio igualmente.
  Future<void> _pickFromCatalog(BuildContext context) async {
    final navigator = Navigator.of(context);
    final chosen = await context.push<Exercise>(TrainingPaths.exercisePicker);
    if (chosen != null) navigator.pop(chosen);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return FractionallySizedBox(
      heightFactor: 0.75,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: TokensSpacing.m),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    l10n.trainingReplaceExercise,
                    style: context.textStyles.titleLarge,
                  ),
                ),
                const SizedBox(height: TokensSpacing.xs),
                Text(
                  l10n.trainingReplaceHint(exerciseName),
                  style: context.textStyles.bodyMedium?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: TokensSpacing.s),
          Expanded(
            child:
                BlocBuilder<
                  ExerciseAlternativesBloc,
                  ExerciseAlternativesState
                >(
                  builder: (context, state) {
                    if (state.loading) {
                      return const AppSkeletonList();
                    }
                    if (state.error != null) {
                      return AppErrorView(
                        error: state.error!,
                        onRetry: () => context
                            .read<ExerciseAlternativesBloc>()
                            .add(ExerciseAlternativesEvent.started(exerciseId)),
                      );
                    }
                    if (state.alternatives.isEmpty) {
                      return AppEmptyState(
                        icon: Icons.swap_horiz_rounded,
                        title: l10n.trainingReplaceEmpty,
                        message: l10n.trainingReplaceEmptyMessage,
                        action: AppSecondaryButton(
                          label: l10n.trainingReplaceFromCatalog,
                          onPressed: () => _pickFromCatalog(context),
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.only(bottom: TokensSpacing.l),
                      itemCount: state.alternatives.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final e = state.alternatives[i];
                        final details = [
                          e.category.label(l10n),
                          if (e.equipment.isNotEmpty) e.equipment.first.name,
                          e.difficulty.label(l10n),
                        ];
                        return AppFocusOutline(
                          child: ListTile(
                            leading: ExerciseThumbnail(
                              url: e.thumbnailUrl,
                              icon: e.category.icon,
                            ),
                            title: Text(e.name),
                            subtitle: Text(details.join(' · ')),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => Navigator.of(context).pop(e),
                          ),
                        );
                      },
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}
