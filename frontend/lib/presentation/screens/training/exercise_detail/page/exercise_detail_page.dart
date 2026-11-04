import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/models/training/exercise.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../widgets/exercise_instructions.dart';
import '../../widgets/exercise_media.dart';
import '../../widgets/training_content.dart';
import '../../widgets/training_labels.dart';
import '../../exercise_guide/page/exercise_guide_section.dart';
import '../bloc/exercise_detail_bloc.dart';

/// Detalle de un ejercicio: demostración, instrucciones, músculos y MET.
class ExerciseDetailPage extends StatelessWidget {
  const ExerciseDetailPage({super.key, required this.exerciseId});

  final String exerciseId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<ExerciseDetailBloc>()
            ..add(ExerciseDetailEvent.started(exerciseId)),
      child: BlocBuilder<ExerciseDetailBloc, ExerciseDetailState>(
        builder: (context, state) => Scaffold(
          appBar: AppPageBar(
            title: Text(switch (state) {
              ExerciseDetailLoaded(:final exercise) => exercise.name,
              _ => context.localizations.trainingExerciseTitle,
            }),
          ),
          body: switch (state) {
            ExerciseDetailLoading() => const AppSkeletonList(
              count: 3,
              height: 160,
            ),
            ExerciseDetailFailure(:final error) => AppErrorView(
              error: error,
              onRetry: () => context.read<ExerciseDetailBloc>().add(
                ExerciseDetailEvent.started(exerciseId),
              ),
            ),
            ExerciseDetailLoaded(:final exercise) => _Content(
              exercise: exercise,
            ),
          },
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final e = exercise;
    return ListView(
      padding: const EdgeInsets.all(TokensSpacing.m),
      children: [
        TrainingContent(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ExerciseMedia(
                gifUrl: e.gifUrl,
                previewUrl: e.previewUrl,
                semanticLabel: l10n.trainingExerciseDemo(e.name),
              ),
              const SizedBox(height: TokensSpacing.m),
              Text(e.name, style: context.textStyles.headlineSmall),
              const SizedBox(height: TokensSpacing.s),
              Wrap(
                spacing: TokensSpacing.xs,
                runSpacing: TokensSpacing.xs,
                children: [
                  AppPill(
                    icon: e.category.icon,
                    label: e.category.label(l10n),
                    color: context.colors.secondary,
                  ),
                  AppPill(
                    icon: Icons.signal_cellular_alt_rounded,
                    label: e.difficulty.label(l10n),
                  ),
                  if (e.circuit)
                    AppPill(
                      icon: Icons.loop_rounded,
                      label: l10n.trainingCircuit,
                    ),
                ],
              ),
              if (e.description != null && e.description!.isNotEmpty) ...[
                const SizedBox(height: TokensSpacing.m),
                Text(e.description!, style: context.textStyles.bodyMedium),
              ],
              if (e.instructions.isNotEmpty) ...[
                const SizedBox(height: TokensSpacing.l),
                AppSectionHeader(title: l10n.trainingInstructions),
                ExerciseInstructions(steps: e.instructions),
              ],
              ExerciseGuideSection(exerciseId: e.id),
              _ItemSection(
                title: l10n.trainingTargetMuscles,
                items: e.targetMuscles,
              ),
              _ItemSection(
                title: l10n.trainingSecondaryMuscles,
                items: e.secondaryMuscles,
              ),
              _ItemSection(title: l10n.trainingBodyParts, items: e.bodyParts),
              _ItemSection(title: l10n.trainingEquipment, items: e.equipment),
              if (e.purposes.isNotEmpty) ...[
                const SizedBox(height: TokensSpacing.l),
                AppSectionHeader(title: l10n.trainingPurposes),
                Wrap(
                  spacing: TokensSpacing.xs,
                  runSpacing: TokensSpacing.xs,
                  children: [
                    for (final p in e.purposes)
                      AppPill(icon: Icons.flag_outlined, label: p),
                  ],
                ),
              ],
              if (e.gifUrl == null && e.previewUrl == null) ...[
                const SizedBox(height: TokensSpacing.l),
                Text(
                  l10n.trainingExerciseSourceOpenGym,
                  style: context.textStyles.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ItemSection extends StatelessWidget {
  const _ItemSection({required this.title, required this.items});

  final String title;
  final List<CatalogItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: TokensSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(title: title),
          Wrap(
            spacing: TokensSpacing.xs,
            runSpacing: TokensSpacing.xs,
            children: [
              for (final item in items)
                Chip(
                  avatar: item.imageUrl == null
                      ? null
                      : CircleAvatar(
                          backgroundImage: CachedNetworkImageProvider(
                            item.imageUrl!,
                          ),
                          onBackgroundImageError: (_, _) {},
                        ),
                  label: Text(item.name),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
