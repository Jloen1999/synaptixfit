import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/models/training/exercise.dart';
import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';
import '../exercise_explorer/bloc/exercise_explorer_bloc.dart';
import 'exercise_thumbnail.dart';
import 'training_labels.dart';

/// Buscador de ejercicios para elegir uno o varios (sesión libre, ADR 0067):
/// el mismo catálogo y bloc que el explorador ([ExerciseExplorerBloc]), con
/// «Por grupo muscular» a un toque y un botón «Añadir/Quitar» en cada fila.
/// [leading] va arriba, antes del buscador, dentro de la misma lista.
class ExercisePickerList extends StatefulWidget {
  const ExercisePickerList({
    super.key,
    required this.selectedIds,
    required this.onToggle,
    this.leading = const [],
    this.autofocus = false,
  });

  final Set<String> selectedIds;
  final ValueChanged<Exercise> onToggle;
  final List<Widget> leading;
  final bool autofocus;

  @override
  State<ExercisePickerList> createState() => _ExercisePickerListState();
}

class _ExercisePickerListState extends State<ExercisePickerList> {
  final _search = TextEditingController();
  Timer? _debounce;

  ExerciseExplorerBloc get _bloc => context.read<ExerciseExplorerBloc>();

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onQuery(String text) {
    _debounce?.cancel();
    _debounce = Timer(AppSearchField.serverDebounce, () {
      if (!mounted) return;
      _bloc.add(
        ExerciseExplorerEvent.criteriaChanged(
          _bloc.state.criteria.copyWith(query: text),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocBuilder<ExerciseExplorerBloc, ExerciseExplorerState>(
      builder: (context, state) {
        final groups = state.filters?.bodyParts ?? const [];
        final selectedGroup = groups
            .where((g) => g.id == state.criteria.bodyPartId)
            .firstOrNull;
        return NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (state.hasMore &&
                n.metrics.pixels >= n.metrics.maxScrollExtent - 400) {
              _bloc.add(const ExerciseExplorerEvent.moreRequested());
            }
            return false;
          },
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  TokensSpacing.m,
                  TokensSpacing.s,
                  TokensSpacing.m,
                  0,
                ),
                sliver: SliverList.list(
                  children: [
                    ...widget.leading,
                    AppSearchField(
                      label: l10n.trainingSearchExercises,
                      controller: _search,
                      autofocus: widget.autofocus,
                      onChanged: _onQuery,
                    ),
                    if (groups.isNotEmpty) ...[
                      const SizedBox(height: TokensSpacing.m),
                      AppSegmentedChoice(
                        label: l10n.trainingFreeByMuscleGroup,
                        values: groups,
                        selected: selectedGroup,
                        labelOf: (g) => g.name,
                        allowEmpty: true,
                        onChanged: (g) => _bloc.add(
                          ExerciseExplorerEvent.criteriaChanged(
                            state.criteria.copyWith(bodyPartId: g?.id),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: TokensSpacing.s),
                  ],
                ),
              ),
              ...switch (state.status) {
                ExplorerStatus.loading => [
                  const SliverToBoxAdapter(
                    child: AppSkeletonList(
                      count: 4,
                      height: TokensSize.skeletonRow,
                    ),
                  ),
                ],
                ExplorerStatus.failure => [
                  SliverToBoxAdapter(
                    child: AppErrorView(
                      error: state.error!,
                      onRetry: () => _bloc.add(
                        ExerciseExplorerEvent.criteriaChanged(state.criteria),
                      ),
                    ),
                  ),
                ],
                ExplorerStatus.ready when state.items.isEmpty => [
                  SliverToBoxAdapter(
                    child: AppEmptyState.compact(
                      icon: Icons.search_off_rounded,
                      title: l10n.trainingNoExercisesTitle,
                      message: l10n.trainingNoExercisesMessage,
                    ),
                  ),
                ],
                ExplorerStatus.ready => [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      TokensSpacing.m,
                      0,
                      TokensSpacing.m,
                      TokensSpacing.l,
                    ),
                    sliver: SliverList.separated(
                      itemCount:
                          state.items.length + (state.loadingMore ? 1 : 0),
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: TokensSpacing.s),
                      itemBuilder: (context, i) {
                        if (i >= state.items.length) {
                          return const AppLoadingView();
                        }
                        final e = state.items[i];
                        return _PickRow(
                          exercise: e,
                          selected: widget.selectedIds.contains(e.id),
                          onToggle: () => widget.onToggle(e),
                        );
                      },
                    ),
                  ),
                ],
              },
            ],
          ),
        );
      },
    );
  }
}

/// Fila de un ejercicio: foto, nombre, categoría y el botón con su nombre
/// («Añadir Sentadilla» / «Quitar Sentadilla»). Elegido se dice con icono y
/// texto, no solo con color.
class _PickRow extends StatelessWidget {
  const _PickRow({
    required this.exercise,
    required this.selected,
    required this.onToggle,
  });

  final Exercise exercise;
  final bool selected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final e = exercise;
    return AppCard(
      onTap: onToggle,
      child: Row(
        children: [
          ExerciseThumbnail(url: e.thumbnailUrl, icon: e.category.icon),
          const SizedBox(width: TokensSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.name, style: context.textStyles.titleSmall),
                const SizedBox(height: TokensSpacing.xxs),
                Text(
                  selected ? l10n.trainingFreeChosen : e.category.label(l10n),
                  style: context.textStyles.bodySmall?.copyWith(
                    color: selected
                        ? context.colors.primary
                        : context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: TokensSpacing.s),
          selected
              ? IconButton.filled(
                  tooltip: l10n.trainingFreeRemoveExercise(e.name),
                  onPressed: onToggle,
                  icon: const Icon(AppIcons.check),
                )
              : IconButton.outlined(
                  tooltip: l10n.trainingFreeAddExercise(e.name),
                  onPressed: onToggle,
                  icon: const Icon(AppIcons.add),
                ),
        ],
      ),
    );
  }
}

/// Hoja «Añadir ejercicio» de la sesión en vivo: un toque en un ejercicio lo
/// devuelve. Usa una hoja (no la ruta del explorador, que vive en la pestaña
/// Entreno y no se apila sobre una pantalla completa).
Future<Exercise?> showAddExerciseSheet(
  BuildContext context, {
  required ExerciseExplorerBloc Function() createBloc,
  Set<String> current = const {},
}) => showModalBottomSheet<Exercise>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  useSafeArea: true,
  builder: (sheetContext) => BlocProvider(
    create: (_) => createBloc()..add(const ExerciseExplorerEvent.started()),
    child: FractionallySizedBox(
      heightFactor: 0.9,
      child: ExercisePickerList(
        autofocus: true,
        selectedIds: current,
        leading: [
          Semantics(
            header: true,
            child: Text(
              sheetContext.localizations.trainingAddExercise,
              style: sheetContext.textStyles.titleLarge,
            ),
          ),
          const SizedBox(height: TokensSpacing.m),
        ],
        onToggle: (e) => Navigator.of(sheetContext).pop(e),
      ),
    ),
  ),
);
